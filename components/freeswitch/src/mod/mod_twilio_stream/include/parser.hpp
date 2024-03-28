#ifndef __PARSER_H__
#define __PARSER_H__

#include <string>
#include <switch_json.h>

#define TYPE_JSON "json"
#define TYPE_TWILIO "twilio_event"

cJSON* parse_json(switch_core_session_t* session, const std::string& data, std::string& type, std::string& sessionId) ;

#endif
