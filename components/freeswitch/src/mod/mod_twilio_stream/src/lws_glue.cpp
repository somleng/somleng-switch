#include <switch.h>
#include <switch_json.h>
#include <string.h>
#include <string>
#include <mutex>
#include <thread>
#include <list>
#include <algorithm>
#include <functional>
#include <cassert>
#include <cstdlib>
#include <fstream>
#include <sstream>
#include <regex>

#include "g711.h"

#include "base64.hpp"
#include "parser.hpp"
#include "mod_twilio_stream.h"
#include "audio_pipe.hpp"
#include "twilio_helper.hpp"

#define RTP_PACKETIZATION_PERIOD 20
#define FRAME_SIZE_8000 320 /*which means each 20ms frame as 320 bytes at 8 khz (1 channel only)*/

namespace
{
  void destroy_tech_pvt(private_t *tech_pvt);
  void send_event(private_t *tech_pvt, switch_core_session_t *session, const char *eventName, const char *json);

  static const char *requestedBufferSecs = std::getenv("MOD_TWILIO_STREAM_BUFFER_SECS");
  static int nAudioBufferSecs = std::max(1, std::min(requestedBufferSecs ? ::atoi(requestedBufferSecs) : 2, 5));
  static const char *requestedInBufferSecs = std::getenv("MOD_TWILIO_STREAM_IN_BUFFER_SECS");
  static int nAudioInBufferSecs = std::max(1, std::min(requestedBufferSecs ? ::atoi(requestedBufferSecs) : 60, 120));
  static const char *requestedBufferStartMSecs = std::getenv("MOD_TWILIO_STREAM_MIN_BUFFER_MILISECS");
  static int nAudioBufferStartMSecs = std::max(0, std::min(requestedBufferStartMSecs ? ::atoi(requestedBufferStartMSecs) : 0, 0));
  static const char *requestedNumServiceThreads = std::getenv("MOD_TWILIO_STREAM_SERVICE_THREADS");
  static const char *mySubProtocolName = std::getenv("MOD_TWILIO_STREAM_SUBPROTOCOL_NAME") ? std::getenv("MOD_TWILIO_STREAM_SUBPROTOCOL_NAME") : "audio.somleng.org";
  static unsigned int nServiceThreads = std::max(1, std::min(requestedNumServiceThreads ? ::atoi(requestedNumServiceThreads) : 1, 5));
  static unsigned int idxCallCount = 0;
  static uint32_t playCount = 0;

  switch_status_t session_cleanup(switch_core_session_t *session, const char *bugname, int channelIsClosing)
  {
    switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_DEBUG, "mod_twilio_stream: fork_session_cleanup\n");
    switch_channel_t *channel = switch_core_session_get_channel(session);
    switch_media_bug_t *bug = (switch_media_bug_t *)switch_channel_get_private(channel, bugname);
    if (!bug)
    {
      switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_DEBUG, "fork_session_cleanup: no bug %s - websocket conection already closed\n", bugname);
      return SWITCH_STATUS_FALSE;
    }
    private_t *tech_pvt = (private_t *)switch_core_media_bug_get_user_data(bug);
    uint32_t id = tech_pvt->id;

    switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_DEBUG, "(%u) fork_session_cleanup\n", id);

    if (!tech_pvt)
      return SWITCH_STATUS_FALSE;
    AudioPipe *pAudioPipe = static_cast<AudioPipe *>(tech_pvt->pAudioPipe);
    TwilioHelper *pTwilioHelper = static_cast<TwilioHelper *>(tech_pvt->pTwilioHelper);

    switch_mutex_lock(tech_pvt->mutex);

    // get the bug again, now that we are under lock
    {
      switch_media_bug_t *bug = (switch_media_bug_t *)switch_channel_get_private(channel, bugname);
      if (bug)
      {
        switch_channel_set_private(channel, bugname, NULL);
        if (!channelIsClosing)
        {
          switch_core_media_bug_remove(session, &bug);
        }
      }
    }

    if (pAudioPipe && pTwilioHelper)
    {
      pTwilioHelper->stop(pAudioPipe);
      send_event(tech_pvt, session, EVENT_DISCONNECT, NULL);
    }

    if (pAudioPipe)
      pAudioPipe->close();

    tech_pvt->pAudioPipe = nullptr;
    tech_pvt->pTwilioHelper = nullptr;

    destroy_tech_pvt(tech_pvt);
    switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_INFO, "(%u) fork_session_cleanup: connection closed\n", id);
    return SWITCH_STATUS_SUCCESS;
  }

  std::string build_json_payload(const char *key, const char *value)
  {
    std::stringstream json;
    json << "{\"" << key << "\":\"" << value << "\"}";
    return json.str();
  }

  void send_event(private_t *tech_pvt, switch_core_session_t *session, const char *eventName, const char *json)
  {
    if (session && tech_pvt)
    {
      if (tech_pvt->pTwilioHelper)
      {
        TwilioHelper *pTwilioHelper = static_cast<TwilioHelper *>(tech_pvt->pTwilioHelper);
        auto wrappedEvent = pTwilioHelper->wrapEvent(eventName, json);
        switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_NOTICE, "send_event: %s\n", wrappedEvent.c_str());
        tech_pvt->responseHandler(session, eventName, wrappedEvent.c_str());
      }
      else
      {
        tech_pvt->responseHandler(session, eventName, json);
      }
    }
  }

  void processIncomingMessage(private_t *tech_pvt, switch_core_session_t *session, const char *message)
  {
    std::string msg = message;
    std::string type;
    std::string streamSid;
    cJSON *json = parse_json(session, msg, type, streamSid);

    if (json)
    {
      TwilioHelper *pTwilioHelper = static_cast<TwilioHelper *>(tech_pvt->pTwilioHelper);
      if (pTwilioHelper)
        if (0 == type.compare("media"))
        {
          cJSON *jsonData = cJSON_GetObjectItem(json, "media");
          if (jsonData)
          {

            const char *payload = cJSON_GetObjectCstr(jsonData, "payload");
            if (payload)
            {

              std::string rawAudio = somleng::base64_decode(payload);
              AudioPipe *pAudioPipe = static_cast<AudioPipe *>(tech_pvt->pAudioPipe);
              pAudioPipe->lockAudioBuffer();
              size_t available = pAudioPipe->binaryReadSpaceAvailable();
              int num_samples_8 = rawAudio.length();

              if (num_samples_8 <= (available * 2))
              {
                for (int i = 0; i < num_samples_8; i++)
                {
                  int16_t sample = ulaw_to_linear(rawAudio.at(i));
                  uint8_t buf[2];
                  memcpy(buf, &sample, sizeof(int16_t));
                  pAudioPipe->binaryReadPush(buf, sizeof(int16_t));
                }
              }
              else
              {
                switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "(%u) dropping incoming packets!\n",
                                  tech_pvt->id);
              }
              pAudioPipe->unlockAudioBuffer();
            }
          }
        }
        else if (0 == type.compare("mark"))
        {
          cJSON *jsonData = cJSON_GetObjectItem(json, "mark");
          if (jsonData)
          {
            const char *name = cJSON_GetObjectCstr(jsonData, "name");
            if (name)
            {
              AudioPipe *pAudioPipe = static_cast<AudioPipe *>(tech_pvt->pAudioPipe);
              if (pAudioPipe != nullptr)
              {
                pAudioPipe->lockAudioBuffer();
                pAudioPipe->binaryReadMark(name);
                pAudioPipe->unlockAudioBuffer();
              }
              auto payload = build_json_payload("mark", name);
              send_event(tech_pvt, session, EVENT_SOCKET_MARK, payload.c_str());
            }
          }
        }
        else if (0 == type.compare("clear"))
        {
          switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_INFO, "(%u) clearing audio \n", tech_pvt->id);
          AudioPipe *pAudioPipe = static_cast<AudioPipe *>(tech_pvt->pAudioPipe);
          TwilioHelper *pTwilioHelper = static_cast<TwilioHelper *>(tech_pvt->pTwilioHelper);
          if (pAudioPipe != nullptr && pTwilioHelper != nullptr)
          {
            pAudioPipe->lockAudioBuffer();
            pAudioPipe->binaryReadClear();
            auto marks = pAudioPipe->clearExpiredMarks();
            for (int i = 0; i < marks.size(); i++)
            {
              pTwilioHelper->mark(pAudioPipe, marks[i]);
              auto payload = build_json_payload("mark", marks[i].c_str());
              send_event(tech_pvt, session, EVENT_MARK, payload.c_str());
            }
            pAudioPipe->unlockAudioBuffer();
          }
          send_event(tech_pvt, session, EVENT_SOCKET_CLEAR, NULL);
        }
        else
        {
          switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_ERROR, "(%u) processIncomingMessage - unsupported msg type %s\n", tech_pvt->id, type.c_str());
        }

      cJSON_Delete(json);
    }
    else
    {
      switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_DEBUG, "(%u) processIncomingMessage - could not parse message: %s\n", tech_pvt->id, message);
    }
  }

  void eventCallback(const char *sessionId, const char *bugname, AudioPipe::NotifyEvent_t event, const char *message)
  {
    switch_core_session_t *session = switch_core_session_locate(sessionId);
    if (session)
    {
      switch_channel_t *channel = switch_core_session_get_channel(session);
      switch_media_bug_t *bug = (switch_media_bug_t *)switch_channel_get_private(channel, bugname);
      if (bug)
      {
        private_t *tech_pvt = (private_t *)switch_core_media_bug_get_user_data(bug);
        if (tech_pvt)
        {
          if (event == AudioPipe::CONNECT_SUCCESS)
          {
            switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_INFO, "connection successful\n");

            AudioPipe *pAudioPipe = static_cast<AudioPipe *>(tech_pvt->pAudioPipe);
            TwilioHelper *pTwilioHelper = static_cast<TwilioHelper *>(tech_pvt->pTwilioHelper);
            pTwilioHelper->connect(pAudioPipe);
            send_event(tech_pvt, session, EVENT_CONNECT_SUCCESS, NULL);
            pTwilioHelper->start(pAudioPipe);
            send_event(tech_pvt, session, EVENT_START, NULL);
          }
          else if (event == AudioPipe::CONNECT_FAIL)
          {
            // first thing: we can no longer access the AudioPipe
            auto payload = build_json_payload("reason", message);
            send_event(tech_pvt, session, EVENT_CONNECT_FAIL, payload.c_str());
            switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_NOTICE, "connection failed: %s\n", message);
            session_cleanup(session, bugname, 0);
          }
          else if (event == AudioPipe::CONNECTION_DROPPED)
          {
            switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_NOTICE, "connection dropped from far end\n");
            session_cleanup(session, bugname, 0);
          }
          else if (event == AudioPipe::CONNECTION_CLOSED_GRACEFULLY)
          {

            switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_DEBUG, "connection closed gracefully\n");
            session_cleanup(session, bugname, 0);
          }
          else if (event == AudioPipe::MESSAGE)
          {
            processIncomingMessage(tech_pvt, session, message);
          }
        }
      }
      switch_core_session_rwunlock(session);
    }
  }

  switch_status_t fork_data_init(private_t *tech_pvt, switch_core_session_t *session, char *host,
                                 unsigned int port, char *path, int sslFlags, int sampling, int desiredSampling, int channels,
                                 char *metadata, const char *bugname, responseHandler_t responseHandler)
  {

    const char *username = nullptr;
    const char *password = nullptr;
    int err;
    switch_codec_implementation_t read_impl;
    switch_channel_t *channel = switch_core_session_get_channel(session);

    switch_core_session_get_read_impl(session, &read_impl);

    if (username = switch_channel_get_variable(channel, "MOD_AUDIO_BASIC_AUTH_USERNAME"))
    {
      password = switch_channel_get_variable(channel, "MOD_AUDIO_BASIC_AUTH_PASSWORD");
    }

    memset(tech_pvt, 0, sizeof(private_t));

    strncpy(tech_pvt->sessionId, switch_core_session_get_uuid(session), MAX_SESSION_ID);
    strncpy(tech_pvt->host, host, MAX_WS_URL_LEN);
    tech_pvt->port = port;
    strncpy(tech_pvt->path, path, MAX_PATH_LEN);
    tech_pvt->sampling = sampling;
    tech_pvt->desiredSampling = desiredSampling;
    tech_pvt->responseHandler = responseHandler;
    tech_pvt->channels = channels;
    tech_pvt->id = ++idxCallCount;
    tech_pvt->buffer_overrun_notified = 0;
    tech_pvt->audio_paused = 0;
    tech_pvt->audio_playing = 0;
    tech_pvt->graceful_shutdown = 0;

    size_t buflen = LWS_PRE + (FRAME_SIZE_8000 * desiredSampling / 8000 * channels * 1000 / RTP_PACKETIZATION_PERIOD * nAudioBufferSecs);
    size_t bufInlen = LWS_PRE + (FRAME_SIZE_8000 * channels * nAudioInBufferSecs);
    
    AudioPipe *ap = new AudioPipe(tech_pvt->sessionId, host, port, path, sslFlags,
                                  buflen, bufInlen, read_impl.decoded_bytes_per_packet, username, password, bugname, eventCallback);
    if (!ap)
    {
      switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "Error allocating AudioPipe\n");
      return SWITCH_STATUS_FALSE;
    }

    tech_pvt->pAudioPipe = static_cast<void *>(ap);

    TwilioHelper *th = new TwilioHelper(metadata);
    if (!th)
    {
      switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "Error allocating TwilioHelper\n");
      return SWITCH_STATUS_FALSE;
    }

    tech_pvt->pTwilioHelper = static_cast<void *>(th);

    switch_mutex_init(&tech_pvt->mutex, SWITCH_MUTEX_NESTED, switch_core_session_get_pool(session));

    if (desiredSampling != sampling)
    {
      // TODO
      switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "Resampling not permitted:.\n");
      return SWITCH_STATUS_FALSE;

      switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_DEBUG, "(%u) resampling from %u to %u\n", tech_pvt->id, sampling, desiredSampling);
      tech_pvt->resampler_out = speex_resampler_init(channels, sampling, desiredSampling, SWITCH_RESAMPLE_QUALITY, &err);
      if (0 != err)
      {
        switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "Error initializing resampler: %s.\n", speex_resampler_strerror(err));
        return SWITCH_STATUS_FALSE;
      }

      tech_pvt->resampler_in = speex_resampler_init(channels, desiredSampling, sampling, SWITCH_RESAMPLE_QUALITY, &err);
      if (0 != err)
      {
        switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "Error initializing resampler: %s.\n", speex_resampler_strerror(err));
        return SWITCH_STATUS_FALSE;
      }
    }
    else
    {
      switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_DEBUG, "(%u) no resampling needed for this call\n", tech_pvt->id);
    }

    switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_DEBUG, "(%u) fork_data_init\n", tech_pvt->id);

    return SWITCH_STATUS_SUCCESS;
  }

  void destroy_tech_pvt(private_t *tech_pvt)
  {
    switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_INFO, "%s (%u) destroy_tech_pvt\n", tech_pvt->sessionId, tech_pvt->id);
    if (tech_pvt->resampler_out)
    {
      speex_resampler_destroy(tech_pvt->resampler_out);
      tech_pvt->resampler_out = nullptr;
    }
    if (tech_pvt->resampler_in)
    {
      speex_resampler_destroy(tech_pvt->resampler_in);
      tech_pvt->resampler_in = nullptr;
    }
    if (tech_pvt->mutex)
    {
      switch_mutex_destroy(tech_pvt->mutex);
      tech_pvt->mutex = nullptr;
    }
  }

  void lws_logger(int level, const char *line)
  {
    switch_log_level_t llevel = SWITCH_LOG_DEBUG;

    switch (level)
    {
    case LLL_ERR:
      llevel = SWITCH_LOG_ERROR;
      break;
    case LLL_WARN:
      llevel = SWITCH_LOG_WARNING;
      break;
    case LLL_NOTICE:
      llevel = SWITCH_LOG_NOTICE;
      break;
    case LLL_INFO:
      llevel = SWITCH_LOG_INFO;
      break;
      break;
    }
    switch_log_printf(SWITCH_CHANNEL_LOG, llevel, "%s\n", line);
  }
}

extern "C"
{
  int parse_ws_uri(switch_channel_t *channel, const char *szServerUri, char *host, char *path, unsigned int *pPort, int *pSslFlags)
  {
    int i = 0, offset;
    char server[MAX_WS_URL_LEN + MAX_PATH_LEN];
    char *saveptr;
    int flags = LCCSCF_USE_SSL;

    if (switch_true(switch_channel_get_variable(channel, "MOD_TWILIO_STREAM_ALLOW_SELFSIGNED")))
    {
      switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_DEBUG, "parse_ws_uri - allowing self-signed certs\n");
      flags |= LCCSCF_ALLOW_SELFSIGNED;
    }
    if (switch_true(switch_channel_get_variable(channel, "MOD_TWILIO_STREAM_SKIP_SERVER_CERT_HOSTNAME_CHECK")))
    {
      switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_DEBUG, "parse_ws_uri - skipping hostname check\n");
      flags |= LCCSCF_SKIP_SERVER_CERT_HOSTNAME_CHECK;
    }
    if (switch_true(switch_channel_get_variable(channel, "MOD_TWILIO_STREAM_ALLOW_EXPIRED")))
    {
      switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_DEBUG, "parse_ws_uri - allowing expired certs\n");
      flags |= LCCSCF_ALLOW_EXPIRED;
    }

    // get the scheme
    strncpy(server, szServerUri, MAX_WS_URL_LEN + MAX_PATH_LEN);
    if (0 == strncmp(server, "https://", 8) || 0 == strncmp(server, "HTTPS://", 8))
    {
      *pSslFlags = flags;
      offset = 8;
      *pPort = 443;
    }
    else if (0 == strncmp(server, "wss://", 6) || 0 == strncmp(server, "WSS://", 6))
    {
      *pSslFlags = flags;
      offset = 6;
      *pPort = 443;
    }
    else if (0 == strncmp(server, "http://", 7) || 0 == strncmp(server, "HTTP://", 7))
    {
      offset = 7;
      *pSslFlags = 0;
      *pPort = 80;
    }
    else if (0 == strncmp(server, "ws://", 5) || 0 == strncmp(server, "WS://", 5))
    {
      offset = 5;
      *pSslFlags = 0;
      *pPort = 80;
    }
    else
    {
      switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_NOTICE, "parse_ws_uri - error parsing uri %s: invalid scheme\n", szServerUri);
      ;
      return 0;
    }

    std::string strHost(server + offset);
    std::regex re("^(.+?):?(\\d+)?(/.*)?$");
    std::smatch matches;
    if (std::regex_search(strHost, matches, re))
    {
      strncpy(host, matches[1].str().c_str(), MAX_WS_URL_LEN);
      if (matches[2].str().length() > 0)
      {
        *pPort = atoi(matches[2].str().c_str());
      }
      if (matches[3].str().length() > 0)
      {
        strncpy(path, matches[3].str().c_str(), MAX_PATH_LEN);
      }
      else
      {
        strcpy(path, "/");
      }
    }
    else
    {
      switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_NOTICE, "parse_ws_uri - invalid format %s\n", strHost.c_str());
      return 0;
    }
    switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_DEBUG, "parse_ws_uri - host %s, path %s\n", host, path);

    return 1;
  }

  switch_status_t fork_init()
  {
    switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_DEBUG, "mod_twilio_stream: fork_init\n");
    switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_NOTICE, "mod_twilio_stream: audio output buffer (in secs):    %d secs\n", nAudioBufferSecs);
    switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_NOTICE, "mod_twilio_stream: audio input buffer (in secs):    %d secs\n", nAudioInBufferSecs);
    switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_NOTICE, "mod_twilio_stream: sub-protocol:              %s\n", mySubProtocolName);
    switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_NOTICE, "mod_twilio_stream: lws service threads:       %d\n", nServiceThreads);

    int logs = LLL_ERR | LLL_WARN | LLL_NOTICE;
    // LLL_INFO | LLL_PARSER | LLL_HEADER | LLL_EXT | LLL_CLIENT  | LLL_LATENCY | LLL_DEBUG ;
    AudioPipe::initialize(mySubProtocolName, nServiceThreads, logs, lws_logger);
    return SWITCH_STATUS_SUCCESS;
  }

  switch_status_t fork_cleanup()
  {
    switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_DEBUG, "mod_twilio_stream: fork_cleanup\n");
    bool cleanup = false;
    cleanup = AudioPipe::deinitialize();
    if (cleanup == true)
    {
      return SWITCH_STATUS_SUCCESS;
    }
    return SWITCH_STATUS_FALSE;
  }

  switch_status_t fork_session_init(switch_core_session_t *session,
                                    responseHandler_t responseHandler,
                                    uint32_t samples_per_second,
                                    char *host,
                                    unsigned int port,
                                    char *path,
                                    int sampling,
                                    int sslFlags,
                                    int channels,
                                    char *metadata,
                                    char *bugname,
                                    void **ppUserData)
  {
    switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_DEBUG, "mod_twilio_stream: fork_session_init\n");
    int err;

    // allocate per-session data structure
    private_t *tech_pvt = (private_t *)switch_core_session_alloc(session, sizeof(private_t));
    if (!tech_pvt)
    {
      switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "error allocating memory!\n");
      return SWITCH_STATUS_FALSE;
    }
    if (SWITCH_STATUS_SUCCESS != fork_data_init(tech_pvt, session, host, port, path, sslFlags, samples_per_second, sampling, channels,
                                                metadata, bugname, responseHandler))
    {
      destroy_tech_pvt(tech_pvt);
      return SWITCH_STATUS_FALSE;
    }

    *ppUserData = tech_pvt;
    return SWITCH_STATUS_SUCCESS;
  }

  switch_status_t fork_session_connect(void **ppUserData)
  {
    private_t *tech_pvt = static_cast<private_t *>(*ppUserData);
    AudioPipe *pAudioPipe = static_cast<AudioPipe *>(tech_pvt->pAudioPipe);
    pAudioPipe->connect();
    return SWITCH_STATUS_SUCCESS;
  }

  switch_status_t fork_session_cleanup(switch_core_session_t *session, const char *bugname, int channelIsClosing)
  {
    return session_cleanup(session, bugname, channelIsClosing);
  }

  switch_status_t fork_session_dtmf_text(switch_core_session_t *session, const char *bugname, const char *match_digits)
  {
    switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_DEBUG, "mod_twilio_stream: fork_session_dtmf_text\n");

    switch_channel_t *channel = switch_core_session_get_channel(session);
    switch_media_bug_t *bug = (switch_media_bug_t *)switch_channel_get_private(channel, bugname);
    if (!bug)
    {
      switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "fork_session_send_text failed because no bug\n");
      return SWITCH_STATUS_FALSE;
    }
    private_t *tech_pvt = (private_t *)switch_core_media_bug_get_user_data(bug);

    if (!tech_pvt)
      return SWITCH_STATUS_FALSE;

    AudioPipe *pAudioPipe = static_cast<AudioPipe *>(tech_pvt->pAudioPipe);
    TwilioHelper *pTwilioHelper = static_cast<TwilioHelper *>(tech_pvt->pTwilioHelper);
    pTwilioHelper->dtmf(pAudioPipe, match_digits);

    auto payload = build_json_payload("dtmf", match_digits);
    send_event(tech_pvt, session, EVENT_DTMF, payload.c_str());

    return SWITCH_STATUS_SUCCESS;
  }

  switch_status_t fork_session_pauseresume(switch_core_session_t *session, const char *bugname, int pause)
  {
    switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_DEBUG, "mod_twilio_stream: fork_session_pauseresume\n");

    switch_channel_t *channel = switch_core_session_get_channel(session);
    switch_media_bug_t *bug = (switch_media_bug_t *)switch_channel_get_private(channel, bugname);
    if (!bug)
    {
      switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "fork_session_pauseresume failed because no bug\n");
      return SWITCH_STATUS_FALSE;
    }
    private_t *tech_pvt = (private_t *)switch_core_media_bug_get_user_data(bug);

    if (!tech_pvt)
      return SWITCH_STATUS_FALSE;

    switch_core_media_bug_flush(bug);
    tech_pvt->audio_paused = pause;
    return SWITCH_STATUS_SUCCESS;
  }

  switch_bool_t fork_frame(switch_core_session_t *session, switch_media_bug_t *bug)
  {
    private_t *tech_pvt = (private_t *)switch_core_media_bug_get_user_data(bug);
    size_t inuse = 0;
    bool dirty = false;
    char *p = (char *)"{\"msg\": \"buffer overrun\"}";

    if (!tech_pvt || tech_pvt->audio_paused || tech_pvt->graceful_shutdown)
      return SWITCH_TRUE;

    if (switch_mutex_trylock(tech_pvt->mutex) == SWITCH_STATUS_SUCCESS)
    {
      if (!tech_pvt->pAudioPipe)
      {
        switch_mutex_unlock(tech_pvt->mutex);
        return SWITCH_TRUE;
      }
      TwilioHelper *pTwilioHelper = static_cast<TwilioHelper *>(tech_pvt->pTwilioHelper);
      AudioPipe *pAudioPipe = static_cast<AudioPipe *>(tech_pvt->pAudioPipe);
      if (pAudioPipe->getLwsState() != AudioPipe::LWS_CLIENT_CONNECTED)
      {
        switch_mutex_unlock(tech_pvt->mutex);
        return SWITCH_TRUE;
      }

      pAudioPipe->lockAudioBuffer();
      size_t available = pAudioPipe->binaryWriteSpaceAvailable();
      if (NULL == tech_pvt->resampler_out)
      {
        switch_frame_t frame = {0};
        frame.data = pAudioPipe->binaryWritePtr();
        frame.buflen = available;
        while (true)
        {

          // check if buffer would be overwritten; dump packets if so
          if (available < pAudioPipe->binaryWriteMinSpace())
          {
            if (!tech_pvt->buffer_overrun_notified)
            {
              tech_pvt->buffer_overrun_notified = 1;
              send_event(tech_pvt, session, EVENT_BUFFER_OVERRUN, NULL);
            }
            switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "(%u) dropping packets!\n",
                              tech_pvt->id);
            pAudioPipe->binaryWritePtrResetToZero();

            frame.data = pAudioPipe->binaryWritePtr();
            frame.buflen = available = pAudioPipe->binaryWriteSpaceAvailable();
          }

          // Process frame from callee
          switch_status_t rv = switch_core_media_bug_read(bug, &frame, SWITCH_TRUE);
          if (rv != SWITCH_STATUS_SUCCESS)
            break;
          if (frame.datalen)
          {
            // Frame for incoming stream
            pTwilioHelper->audio(pAudioPipe, true, (int16_t *)frame.data, frame.datalen / 2);
          }
        }
      }
      else
      {
        uint8_t data[SWITCH_RECOMMENDED_BUFFER_SIZE];
        switch_frame_t frame = {0};
        frame.data = data;
        frame.buflen = SWITCH_RECOMMENDED_BUFFER_SIZE;
        while (switch_core_media_bug_read(bug, &frame, SWITCH_TRUE) == SWITCH_STATUS_SUCCESS)
        {
          if (frame.datalen)
          {
            spx_uint32_t out_len = available >> 1; // space for samples which are 2 bytes
            spx_uint32_t in_len = frame.samples;

            speex_resampler_process_interleaved_int(tech_pvt->resampler_out,
                                                    (const spx_int16_t *)frame.data,
                                                    (spx_uint32_t *)&in_len,
                                                    (spx_int16_t *)((char *)pAudioPipe->binaryWritePtr()),
                                                    &out_len);

            if (out_len > 0)
            {
              // Note because ther binaryWritePtrAdd is not called here the audio data is store in a temporary way and each call will overrite the previous call.
              // It is basically using the AudioPipe as a temporay buffer for the transformed frame.
              // Data will be at pAudioPipe->binaryWritePtr() + output_len. L16 format

              // bytes written = num samples * 2 * num channels
              size_t bytes_written = out_len << tech_pvt->channels;
              pTwilioHelper->audio(pAudioPipe, true, (int16_t *)pAudioPipe->binaryWritePtr(), bytes_written / 2);
              available = pAudioPipe->binaryWriteSpaceAvailable();
            }
            if (available < pAudioPipe->binaryWriteSpaceAvailable())
            {
              if (!tech_pvt->buffer_overrun_notified)
              {
                tech_pvt->buffer_overrun_notified = 1;
                switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "(%u) dropping packets!\n",
                                  tech_pvt->id);
                send_event(tech_pvt, session, EVENT_BUFFER_OVERRUN, NULL);
              }
              break;
            }
          }
        }
      }

      pAudioPipe->unlockAudioBuffer();
      switch_mutex_unlock(tech_pvt->mutex);
    }
    return SWITCH_TRUE;
  }

  switch_bool_t fork_write_audio(switch_core_session_t *session, switch_media_bug_t *bug)
  {
    switch_frame_t *frame;
    private_t *tech_pvt = (private_t *)switch_core_media_bug_get_user_data(bug);
    AudioPipe *pAudioPipe = static_cast<AudioPipe *>(tech_pvt->pAudioPipe);
    if (!tech_pvt || tech_pvt->audio_paused || tech_pvt->graceful_shutdown || !pAudioPipe)
      return SWITCH_TRUE;

    int available = pAudioPipe->binaryReadPtrCount();
    if (available <= 0)
    {
      tech_pvt->audio_playing = false;
      return SWITCH_TRUE;
    }

    int minBuffer = (tech_pvt->desiredSampling * 2 * tech_pvt->channels) * (nAudioBufferStartMSecs / 1000.0);

    if (!tech_pvt->audio_playing && available < minBuffer)
    {
      switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "(%u) buffer not full (%d, %d)  \n",
                        tech_pvt->id,
                        available, minBuffer);
      return SWITCH_TRUE;
    }    

    if (switch_mutex_trylock(tech_pvt->mutex) == SWITCH_STATUS_SUCCESS)
    {
      pAudioPipe->lockAudioBuffer();
      frame = switch_core_media_bug_get_write_replace_frame(bug);
      if (frame)
      {
        int num_samples = 0;
        if (NULL == tech_pvt->resampler_in)
        {
          num_samples = pAudioPipe->binaryReadPop((uint8_t *)frame->data, frame->datalen);
        }
        else
        {
          auto sample_ratio = ((float)tech_pvt->desiredSampling) / ((float)tech_pvt->sampling);
          num_samples = pAudioPipe->binaryReadPop((uint8_t *)frame->data, frame->samples * 2 * sample_ratio);
          spx_uint32_t in_len = num_samples * 2; // space for samples which are 2 bytes
          spx_uint32_t out_len = frame->samples;
          speex_resampler_process_interleaved_int(tech_pvt->resampler_in,
                                                  (const spx_int16_t *)frame->data,
                                                  (spx_uint32_t *)&in_len,
                                                  (spx_int16_t *)((char *)frame->data),
                                                  &out_len);
        }
        if (num_samples > 0)
        {
          tech_pvt->audio_playing = true;
          switch_core_media_bug_set_write_replace_frame(bug, frame);

          TwilioHelper *pTwilioHelper = static_cast<TwilioHelper *>(tech_pvt->pTwilioHelper);
          if (pTwilioHelper)
          {

            auto marks = pAudioPipe->clearExpiredMarks();
            switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_INFO, "(%u) buffer clearExpiredMarks (%d)  \n",
            tech_pvt->id,
            marks.size());
            for (int i = 0; i < marks.size(); i++)
            {
              pTwilioHelper->mark(pAudioPipe, marks[i]);
              auto payload = build_json_payload("mark", marks[i].c_str());
              send_event(tech_pvt, session, EVENT_MARK, payload.c_str());
            }
          }
        }
      }

      pAudioPipe->unlockAudioBuffer();
      switch_mutex_unlock(tech_pvt->mutex);
    }
    return SWITCH_TRUE;
  }
}