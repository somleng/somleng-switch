/*
 *
 * mod_twilio_stream.c -- Freeswitch module for forking audio to remote server over websockets
 *
 */
#include "mod_twilio_stream.h"
#include "lws_glue.h"

// static int mod_running = 0;

SWITCH_MODULE_SHUTDOWN_FUNCTION(mod_twilio_stream_shutdown);
SWITCH_MODULE_RUNTIME_FUNCTION(mod_twilio_stream_runtime);
SWITCH_MODULE_LOAD_FUNCTION(mod_twilio_stream_load);

SWITCH_MODULE_DEFINITION(mod_twilio_stream, mod_twilio_stream_load, mod_twilio_stream_shutdown, NULL /*mod_twilio_stream_runtime*/);

static void responseHandler(switch_core_session_t *session, const char *eventName, const char *json)
{
	switch_event_t *event;

	switch_channel_t *channel = switch_core_session_get_channel(session);
	if (json)
		switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_DEBUG, "responseHandler: sending event payload: %s.\n", json);
	switch_event_create_subclass(&event, SWITCH_EVENT_CUSTOM, eventName);
	switch_channel_event_set_data(channel, event);
	switch_event_add_header_string(event, SWITCH_STACK_BOTTOM, "Event-Payload", json);
	switch_event_fire(&event);
}

/*
  dtmf handler function you can hook up to be executed when a digit is dialed during playback
  if you return anything but SWITCH_STATUS_SUCCESS the playback will stop.
*/
static switch_status_t on_dtmf(switch_core_session_t *session, const switch_dtmf_t *dtmf, switch_dtmf_direction_t direction)
{
	switch_media_bug_t *bug;
	switch_channel_t *channel = switch_core_session_get_channel(session);
	if ((bug = (switch_media_bug_t *)switch_channel_get_private(channel, BUG_NAME)))
	{
		private_t *tech_pvt = (private_t *)switch_core_media_bug_get_user_data(bug);
		if (tech_pvt)
		{
			char digits[2] = {0};
			digits[0] = dtmf->digit;
			fork_session_dtmf_text(session, BUG_NAME, digits);
		}

		return SWITCH_STATUS_FALSE;
	}
	return SWITCH_STATUS_SUCCESS;
}

static switch_bool_t capture_callback(switch_media_bug_t *bug, void *user_data, switch_abc_type_t type)
{
	switch_core_session_t *session = switch_core_media_bug_get_session(bug);
	switch (type)
	{
	case SWITCH_ABC_TYPE_INIT:
		switch_core_event_hook_add_recv_dtmf(session, on_dtmf);
		break;

	case SWITCH_ABC_TYPE_CLOSE:
	{
		switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_INFO, "Got SWITCH_ABC_TYPE_CLOSE for bug %s\n", BUG_NAME);
		fork_session_cleanup(session, BUG_NAME, 1);

		switch_core_event_hook_remove_recv_dtmf(session, on_dtmf);
	}
	break;

	case SWITCH_ABC_TYPE_READ:
		return fork_frame(session, bug);
		break;
	case SWITCH_ABC_TYPE_WRITE_REPLACE:
		return fork_write_audio(session, bug);
		break;

	default:
		break;
	}

	return SWITCH_TRUE;
}

static switch_status_t start_capture(switch_core_session_t *session,
									 switch_media_bug_flag_t flags,
									 char *host,
									 unsigned int port,
									 char *path,
									 int sampling,
									 int sslFlags,
									 char *metadata,
									 const char *bugname)
{
	switch_channel_t *channel = switch_core_session_get_channel(session);
	switch_media_bug_t *bug;
	switch_status_t status;
	switch_codec_t *read_codec;

	void *pUserData = NULL;
	int channels = (flags & SMBF_STEREO) ? 2 : 1;

	switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_INFO,
					  "mod_twilio_stream (%s): streaming %d sampling to %s path %s port %d tls: %s.\n",
					  bugname, sampling, host, path, port, sslFlags ? "yes" : "no");

	if (switch_channel_get_private(channel, bugname))
	{
		switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "mod_twilio_stream: bug %s already attached!\n", bugname);
		return SWITCH_STATUS_FALSE;
	}

	read_codec = switch_core_session_get_read_codec(session);

	if (switch_channel_pre_answer(channel) != SWITCH_STATUS_SUCCESS)
	{
		switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "mod_twilio_stream: channel must have reached pre-answer status before calling start!\n");
		return SWITCH_STATUS_FALSE;
	}

	switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_DEBUG, "calling fork_session_init.\n");
	if (SWITCH_STATUS_FALSE == fork_session_init(session, responseHandler, read_codec->implementation->actual_samples_per_second,
												 host, port, path, sampling, sslFlags, channels, metadata, bugname, &pUserData))
	{
		switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "Error initializing mod_twilio_stream session.\n");
		return SWITCH_STATUS_FALSE;
	}
	switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_DEBUG, "adding bug %s.\n", bugname);
	if ((status = switch_core_media_bug_add(session, bugname, NULL, capture_callback, pUserData, 0, flags, &bug)) != SWITCH_STATUS_SUCCESS)
	{
		return status;
	}
	switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_DEBUG, "setting bug private data %s.\n", bugname);
	switch_channel_set_private(channel, bugname, bug);

	if (fork_session_connect(&pUserData) != SWITCH_STATUS_SUCCESS)
	{
		switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "Error mod_twilio_stream session cannot connect.\n");
		return SWITCH_STATUS_FALSE;
	}

	switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_DEBUG, "exiting start_capture.\n");
	return SWITCH_STATUS_SUCCESS;
}

static switch_status_t do_stop(switch_core_session_t *session, const char *bugname)
{
	switch_status_t status = SWITCH_STATUS_SUCCESS;

	switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_INFO, "mod_twilio_stream (%s): stop\n", bugname);
	status = fork_session_cleanup(session, bugname, 0);

	return status;
}

static switch_status_t do_pauseresume(switch_core_session_t *session, const char *bugname, int pause)
{
	switch_status_t status = SWITCH_STATUS_SUCCESS;

	switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_INFO, "mod_twilio_stream (%s): %s\n", bugname, pause ? "pause" : "resume");
	status = fork_session_pauseresume(session, bugname, pause);

	return status;
}

#define FORK_API_SYNTAX "<uuid> [start | stop | pause | resume ] [wss-url | path] [metadata]"
SWITCH_STANDARD_API(fork_function)
{
	char *mycmd = NULL, *argv[4] = {0};
	int argc = 0;
	switch_status_t status = SWITCH_STATUS_FALSE;
	const char *bugname = BUG_NAME;
	char *metadata = "";

	if (!zstr(cmd) && (mycmd = strdup(cmd)))
	{
		argc = switch_separate_string(mycmd, ' ', argv, (sizeof(argv) / sizeof(argv[0])));
	}
	assert(cmd);
	switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_DEBUG, "mod_twilio_stream cmd: %s\n", cmd);

	if (zstr(cmd) || argc < 2 ||
		(0 == strcmp(argv[1], "start") && argc < 3))
	{

		switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "Error with command %s %s %s.\n", cmd, argv[0], argv[1]);
		stream->write_function(stream, "-USAGE: %s\n", FORK_API_SYNTAX);
		goto done;
	}
	else
	{
		switch_core_session_t *lsession = NULL;

		if ((lsession = switch_core_session_locate(argv[0])))
		{
			if (!strcasecmp(argv[1], "stop"))
			{
				status = do_stop(lsession, bugname);
			}
			else if (!strcasecmp(argv[1], "pause"))
			{

				status = do_pauseresume(lsession, bugname, 1);
			}
			else if (!strcasecmp(argv[1], "resume"))
			{
				status = do_pauseresume(lsession, bugname, 0);
			}
			else if (!strcasecmp(argv[1], "start"))
			{
				switch_channel_t *channel = switch_core_session_get_channel(lsession);
				char host[MAX_WS_URL_LEN], path[MAX_PATH_LEN];
				unsigned int port;
				int sslFlags;
				int sampling = 8000;
				switch_media_bug_flag_t flags = SMBF_READ_STREAM;

				metadata = argv[3];

				// Should always be mixed
				flags |= SMBF_WRITE_STREAM;
				flags |= SMBF_READ_REPLACE;
				flags |= SMBF_WRITE_REPLACE;
				sampling = 8000;

				if (!parse_ws_uri(channel, argv[2], &host[0], &path[0], &port, &sslFlags))
				{
					switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "invalid websocket uri: %s\n", argv[2]);
				}
				else if (sampling % 8000 != 0)
				{
					switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "invalid sample rate: %s\n", argv[4]);
				}
								status = start_capture(lsession, flags, host, port, path, sampling, sslFlags, metadata, bugname);
							}
			else
			{
				switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "unsupported mod_twilio_stream cmd: %s\n", argv[1]);
			}
			switch_core_session_rwunlock(lsession);
		}
		else
		{
			switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_ERROR, "Error locating session %s\n", argv[0]);
		}
	}

	if (status == SWITCH_STATUS_SUCCESS)
	{
		stream->write_function(stream, "+OK Success\n");
	}
	else
	{
		stream->write_function(stream, "-ERR Operation Failed\n");
	}

done:
	
	switch_safe_free(mycmd);
	return SWITCH_STATUS_SUCCESS;
}

SWITCH_MODULE_LOAD_FUNCTION(mod_twilio_stream_load)
{
	switch_api_interface_t *api_interface;

	switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_NOTICE, "mod_twilio_stream API loading..\n");

	/* connect my internal structure to the blank pointer passed to me */
	*module_interface = switch_loadable_module_create_module_interface(pool, modname);

	/* create/register custom event message types */
	const char *allEvents[] = ALL_EVENTS;
	for (size_t i = 0; i < sizeof(allEvents) / sizeof(char *); i++)
	{
		if (switch_event_reserve_subclass(allEvents[i]) != SWITCH_STATUS_SUCCESS)
		{
			switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_ERROR, "Couldn't register an event subclass for mod_twilio_stream API.\n");
			return SWITCH_STATUS_TERM;
		}
	}

	SWITCH_ADD_API(api_interface, "uuid_twilio_stream", "twilio_stream API", fork_function, FORK_API_SYNTAX);
	switch_console_set_complete("add uuid_twilio_stream start wss-url");
	switch_console_set_complete("add uuid_twilio_stream stop");

	fork_init();

	switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_NOTICE, "mod_twilio_stream API successfully loaded\n");

	/* indicate that the module should continue to be loaded */
	// mod_running = 1;
	return SWITCH_STATUS_SUCCESS;
}

/*
  Called when the system shuts down
  Macro expands to: switch_status_t mod_twilio_stream_shutdown() */
SWITCH_MODULE_SHUTDOWN_FUNCTION(mod_twilio_stream_shutdown)
{
	fork_cleanup();
	// mod_running = 0;
	const char *allEvents[] = ALL_EVENTS;
	for (size_t i = 0; i < sizeof(allEvents) / sizeof(char *); i++)
	{
		switch_event_free_subclass(allEvents[i]);
	}

	return SWITCH_STATUS_SUCCESS;
}

/*
  If it exists, this is called in it's own thread when the module-load completes
  If it returns anything but SWITCH_STATUS_TERM it will be called again automatically
  Macro expands to: switch_status_t mod_twilio_stream_runtime()
*/
/*
SWITCH_MODULE_RUNTIME_FUNCTION(mod_twilio_stream_runtime)
{
  fork_service_threads(&mod_running);
	return SWITCH_STATUS_TERM;
}
*/
