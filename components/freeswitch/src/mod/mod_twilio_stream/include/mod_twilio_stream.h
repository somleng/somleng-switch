#ifndef __MOD_FORK_TWILIO_H__
#define __MOD_FORK_TWILIO_H__

#include <switch.h>
#include <libwebsockets.h>
#include <speex/speex_resampler.h>

#include <unistd.h>

#define MAX_BUG_LEN (64)
#define MAX_SESSION_ID (256)
#define MAX_WS_URL_LEN (512)
#define MAX_PATH_LEN (4096)

#define EVENT_BUFFER_OVERRUN "mod_twilio_stream::buffer_overrun"
#define EVENT_CONNECT_FAIL "mod_twilio_stream::connect_failed"
#define EVENT_CONNECT_SUCCESS "mod_twilio_stream::connect"
#define EVENT_DISCONNECT "mod_twilio_stream::disconnect"
#define EVENT_DTMF "mod_twilio_stream::dtmf"
#define EVENT_ERROR "mod_twilio_stream::error"
#define EVENT_MARK "mod_twilio_stream::mark"
#define EVENT_SOCKET_CLEAR "mod_twilio_stream::socket_clear"
#define EVENT_SOCKET_MARK "mod_twilio_stream::socket_mark"
#define EVENT_START "mod_twilio_stream::start"
//Make sure the above and below stays in sync!!!
#define ALL_EVENTS {EVENT_BUFFER_OVERRUN,EVENT_CONNECT_FAIL,EVENT_CONNECT_SUCCESS,EVENT_DISCONNECT,EVENT_DTMF,EVENT_ERROR,EVENT_MARK,EVENT_SOCKET_CLEAR,EVENT_SOCKET_MARK, EVENT_START}


#define BUG_NAME "__mod_twilio_stream"

struct playout
{
  char *file;
  struct playout *next;
};

typedef void (*responseHandler_t)(switch_core_session_t *session, const char *eventName, const char *json);

struct private_data
{
  switch_mutex_t *mutex;
  char sessionId[MAX_SESSION_ID];
  SpeexResamplerState *resampler_out;
  SpeexResamplerState *resampler_in;
  responseHandler_t responseHandler;
  void *pAudioPipe;
  void *pTwilioHelper;
  int ws_state;
  char host[MAX_WS_URL_LEN];
  unsigned int port;
  char path[MAX_PATH_LEN];
  int sampling;        // call sample rate
  int desiredSampling; // twilio sample rate
  int channels;
  unsigned int id;
  int buffer_overrun_notified : 1;
  int audio_paused : 1;
  int graceful_shutdown : 1;
};

typedef struct private_data private_t;

#endif
