#include "parser.hpp"
#include <switch.h>

cJSON *parse_json(switch_core_session_t *session, const std::string &data, std::string &type, std::string &sessionId)
{
  cJSON *json = NULL;
  const char *szEvent = NULL;
  const char *szSId = NULL;

  json = cJSON_Parse(data.c_str());
  if (!json)
  {
    switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "parse - failed parsing incoming msg as JSON: %s\n", data.c_str());
    return NULL;
  }

  szEvent = cJSON_GetObjectCstr(json, "event");
  if (szEvent)
  {
    type.assign(szEvent);
  }

  szSId = cJSON_GetObjectCstr(json, "streamSid");
  if (szSId)
  {
    sessionId.assign(szSId);
  }
  return json;
}

