#ifndef __TWILIO_HELPER_HPP__
#define __TWILIO_HELPER_HPP__

#include <string>
#include <list>
#include <mutex>
#include <queue>
#include <unordered_map>
#include <thread>

#include "audio_pipe.hpp"

class TwilioHelper
{
public:
  TwilioHelper(const char *config);
  ~TwilioHelper();

  void connect(AudioPipe *pAudioPipe);
  void start(AudioPipe *pAudioPipe);
  void stop(AudioPipe *pAudioPipe);
  void dtmf(AudioPipe *pAudioPipe, const char *digits);
  void dtmf_single(AudioPipe *pAudioPipe, char digit);
  void mark(AudioPipe *pAudioPipe, std::string name);
  void audio(AudioPipe *pAudioPipe, bool inbound, int16_t *samples, int num_samples);

  std::string getStreamId(void)
  {
    return m_stream_sid;
  }

private:
  unsigned int get_incr_seq_num();
  unsigned int get_incr_chunk_num(bool inbound);

  unsigned int m_seq_num = 1;
  unsigned int m_chunk_num[2] = {1, 1}; // inbound, outbound
  unsigned long m_stream_start;         // the time in ms at start

  // Metadata
  std::string m_account_sid;
  std::string m_call_sid;
  std::string m_stream_sid;
  std::string m_custom_parameters;

  bool m_isstart;
  bool m_isstop;

  std::mutex m_seq_mutex;
};

#endif
