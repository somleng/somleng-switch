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

#define EVENT_TRANSCRIPTION   "mod_twilio_stream::transcription"
#define EVENT_TRANSFER        "mod_twilio_stream::transfer"
#define EVENT_PLAY_AUDIO      "mod_twilio_stream::play_audio"
#define EVENT_KILL_AUDIO      "mod_twilio_stream::kill_audio"
#define EVENT_DISCONNECT      "mod_twilio_stream::disconnect"
#define EVENT_ERROR           "mod_twilio_stream::error"
#define EVENT_CONNECT_SUCCESS "mod_twilio_stream::connect"
#define EVENT_CONNECT_FAIL    "mod_twilio_stream::connect_failed"
#define EVENT_BUFFER_OVERRUN  "mod_twilio_stream::buffer_overrun"
#define EVENT_JSON            "mod_twilio_stream::json"

#define MAX_METADATA_LEN (8192)
#define BUG_NAME "__mod_twilio_stream"

struct playout {
  char *file;
  struct playout* next;
};

typedef void (*responseHandler_t)(switch_core_session_t* session, const char* eventName, char* json);

struct private_data {
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
  int sampling; //call sample rate
  int desiredSampling; //twilio sample rate
  int  channels;
  unsigned int id;
  int buffer_overrun_notified:1;
  int audio_paused:1;
  int graceful_shutdown:1;
  char initialMetadata[8192];
};

typedef struct private_data private_t;

#endif
