#include "twilio_helper.hpp"
#include <string.h>
#include <string>
#include <sstream>
#include <chrono>
#include <switch_json.h>
#include "g711.h"
#include "base64.hpp"

#include "lockfree/lockfree.hpp"

using namespace std::chrono;

TwilioHelper::TwilioHelper(const char *config)
{
  std::string parsedConfig = drachtio::base64_decode(std::string(config));
  cJSON *json = cJSON_Parse(parsedConfig.c_str());
  if (json)
  {
    auto call_sid = cJSON_GetObjectCstr(json, "call_sid");
    if (call_sid)
      m_call_sid = std::string(call_sid);
    auto account_sid = cJSON_GetObjectCstr(json, "account_sid");
    if (account_sid)
      m_account_sid = std::string(account_sid);
    auto stream_sid = cJSON_GetObjectCstr(json, "stream_sid");
    if (stream_sid)
      m_stream_sid = std::string(stream_sid);

    auto customParameters = cJSON_GetObjectItem(json, "custom_parameters");
    if (customParameters)
    {
      auto customParametersFormat = cJSON_PrintUnformatted(customParameters);
      if (customParametersFormat)
      {
        m_custom_parameters = std::string(customParametersFormat);
        free(customParametersFormat);
      }
      else
      {
        lwsl_notice("TwilioHelper:: Unable to process custom properties sub %s\n", parsedConfig.c_str());
      }
    }
    else
    {
      lwsl_notice("TwilioHelper:: Unable to process custom properties %s\n", parsedConfig.c_str());
    }
    cJSON_Delete(json);
  }
  else
  {
    lwsl_notice("TwilioHelper:: Unable to process metadata %s\n", parsedConfig.c_str());
  }

  m_isstart = true;
  m_isstop = false;
}

void TwilioHelper::connect(AudioPipe *pAudioPipe)
{
  if (pAudioPipe == nullptr)
    return;
  std::stringstream json;
  json << R"({ 
    "event": "connected",
    "protocol": "Call", 
    "version": "1.0.0"
  })";
  pAudioPipe->bufferForSending(json.str().c_str());
}

void TwilioHelper::start(AudioPipe *pAudioPipe)
{
  if (pAudioPipe == nullptr)
    return;
  auto seq = get_incr_seq_num();
  m_stream_start = duration_cast<milliseconds>(system_clock::now().time_since_epoch()).count();
  m_isstart = true;
  m_isstop = false;

  std::stringstream json;
  json << R"({"event": "start",)";
  json << R"("sequenceNumber": ")" << seq << "\",";
  json << R"("start": {)";
  json << R"("accountSid": ")" << m_account_sid << "\",";
  json << R"("callSid": ")" << m_call_sid << "\",";
  json << R"("tracks": ["inbound","outbound"],)";
  json << R"("mediaFormat": {)";
  json << R"("encoding": "audio/x-mulaw",)";
  json << R"("sampleRate": 8000,)";
  json << R"("channels": 1}},)";
  if (!m_custom_parameters.empty())
  {
    json << R"("customParameters": )" << m_custom_parameters << ",";
  }

  json << R"("streamSid": ")" << m_stream_sid << "\"}";

  pAudioPipe->bufferForSending(json.str().c_str());
}

void TwilioHelper::stop(AudioPipe *pAudioPipe)
{
  if (pAudioPipe == nullptr)
    return;
  if (m_isstart && !m_isstop)
  {
    m_isstart = false;
    m_isstop = true;
    auto seq = get_incr_seq_num();
    std::stringstream json;
    json << R"({"event": "stop",)";
    json << R"("sequenceNumber": ")" << seq << "\",";
    json << R"("stop": {)";
    json << R"("accountSid": ")" << m_account_sid << "\",";
    json << R"("callSid": ")" << m_call_sid << "\"},";
    json << R"("streamSid": ")" << m_stream_sid << "\"}";
    pAudioPipe->bufferForSending(json.str().c_str());
  }
}

void TwilioHelper::dtmf(AudioPipe *pAudioPipe, const char *digits)
{
  std::string strDigits = std::string(digits);
  for (int i = 0; i < strDigits.length(); i++)
    dtmf_single(pAudioPipe, strDigits.at(i));
}

void TwilioHelper::dtmf_single(AudioPipe *pAudioPipe, char digit)
{
  if (pAudioPipe == nullptr)
    return;
  auto seq = get_incr_seq_num();
  std::stringstream json;
  json << R"({"event": "dtmf",)";
  json << R"("streamSid":")" << m_stream_sid << "\",";
  json << R"("sequenceNumber":")" << seq << "\",";
  json << R"("dtmf": { )";
  json << R"("track":"inbound_track",)";
  json << R"("digit": ")" << digit << "\"}}";
  pAudioPipe->bufferForSending(json.str().c_str());
}

void TwilioHelper::mark(AudioPipe *pAudioPipe, std::string name)
{
  if (pAudioPipe == nullptr)
    return;
  auto seq = get_incr_seq_num();
  std::stringstream json;
  json << R"({"event": "mark",)";
  json << R"("sequenceNumber": ")" << seq << "\",";
  json << R"("streamSid":")" << m_stream_sid << "\",";
  json << R"("mark": {)";
  json << R"("name": ")" << name << "\"}}";
  pAudioPipe->bufferForSending(json.str().c_str());
}

void TwilioHelper::audio(AudioPipe *pAudioPipe, bool inbound, int16_t *samples, int num_samples)
{
  if (pAudioPipe == nullptr)
    return;
  auto seq = get_incr_seq_num();
  auto track = inbound ? "inbound" : "outbound";
  auto chunk = get_incr_chunk_num(inbound);
  auto now = duration_cast<milliseconds>(system_clock::now().time_since_epoch()).count();
  auto timestamp = now - m_stream_start;

  std::stringstream base64data;
  for (int i = 0; i < num_samples; i++)
    base64data << (char)linear_to_ulaw(samples[i]);

  std::string payload = drachtio::base64_encode(base64data.str());

  std::stringstream json;
  json << R"({ )";
  json << R"("event": "media",)";
  json << R"("sequenceNumber": ")" << seq << "\",";
  json << R"("media": {)";
  json << R"("track": ")" << track << "\",";
  json << R"("chunk": ")" << chunk << "\",";
  json << R"("timestamp": ")" << timestamp << "\",";
  json << R"("payload": ")"
       << payload
       << "\"},";
  json << R"("streamSid": ")" << m_stream_sid << "\"}";

  pAudioPipe->bufferForSending(json.str().c_str());
}

std::string TwilioHelper::wrapEvent(const char *event, const char *payload)
{
  std::string fullEventName = std::string(event);
  std::string eventName = fullEventName.substr(fullEventName.find_last_of("::") + 1);
  std::stringstream json;
  json << R"({"event": ")" << eventName << "\",";
  json << R"("accountSid": ")" << m_account_sid << "\",";
  json << R"("callSid": ")" << m_call_sid << "\",";
  if (payload)
  {
    json << R"("payload": )" << payload << ",";
  }
  json << R"("streamSid": ")" << m_stream_sid << "\"}";
  return json.str();
}

unsigned int TwilioHelper::get_incr_seq_num()
{
  std::lock_guard<std::mutex> lk(m_seq_mutex);
  auto seq = m_seq_num++;
  return seq;
}

unsigned int TwilioHelper::get_incr_chunk_num(bool inbound)
{
  std::lock_guard<std::mutex> lk(m_seq_mutex);
  auto chunk = m_chunk_num[inbound ? 0 : 1]++;
  return chunk;
}
