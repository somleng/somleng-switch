class DrbEndpoint
  # Do not use instance variables in this class!
  # If an instance variable is set,
  # the next time this DrbEndpoint is invoked it will use the previous instance variable

  DEFAULT_DIAL_STRING_FORMAT = "%{destination}"

  def initiate_outbound_call!(call_json)
    logger.info("Receiving DRb request: #{call_json}")
    call_params = JSON.parse(call_json)
    call_variables = get_call_variables(call_params)

    call_args = [
      call_variables[:dial_string],
      {
        :from => call_variables[:caller_id],
        :controller => CallController,
        :controller_metadata => controller_metadata(call_variables),
        :headers => construct_adhearsion_twilio_headers(call_variables)
      }
    ]

    if call_variables[:disable_originate].to_i != 1
      logger.info("Initiating outbound call with: #{call_args}")
      outbound_call = Adhearsion::OutboundCall.originate(*call_args)
      register_event_end(outbound_call)
      outbound_call.id
    end
  end

  private

  def register_event_end(outbound_call)
    outbound_call.register_event_handler(Adhearsion::Event::End) do |event|
      handle_event_end(event)
    end
  end

  def handle_event_end(event)
    logger.info("handle_event_end - event: #{event}")
    event_details = parse_event(event)
    notify_status_callback_url(event_details) if !answered?(event_details)
  end

  def answered?(event_details)
    event_details[:sip_term_status] == "200"
  end

  def construct_adhearsion_twilio_headers(call_variables)
    sip_header_util = Adhearsion::Twilio::Util::SipHeader.new
    {
      sip_header_util.construct_header_name("Status-Callback-Url") => call_variables[:status_callback_url]
    }
  end

  def parse_event(event)
    headers = event.headers
    {
      :sip_term_status => headers["variable-sip_term_status"],
      :status_callback_url => headers["X-Adhearsion-Twilio-Status-Callback-Url"]
    }
  end

  def notify_status_callback_url(event_details)
    configuration = Adhearsion::Twilio::Configuration.new
    http_client = Adhearsion::Twilio::HttpClient.new(
      :status_callback_url => event_details[:status_callback_url] || configuration.status_callback_url,
      :status_callback_method => event_details[:status_callback_method] || configuration.status_callback_method,
      :call_sid => event_details[:outbound_call_sid],
      :call_to => event_details[:call_to],
      :call_from => event_details[:call_from],
      :call_direction => event_details[:call_direction],
      :auth_token => event_details[:auth_token],
      :logger => logger
    )

    http_client.notify_status_callback_url(:no_answer)
  end

  def call_direction
    :outbound_api
  end

  def get_routing_instructions(call_params)
    call_params["routing_instructions"] || {}
  end

  def controller_metadata(call_variables)
    {
      :voice_request_url => call_variables[:voice_request_url],
      :voice_request_method => call_variables[:voice_request_method],
      :status_callback_url => call_variables[:status_callback_url],
      :status_callback_method => call_variables[:status_callback_method],
      :account_sid => call_variables[:account_sid],
      :auth_token => call_variables[:auth_token],
      :call_sid => call_variables[:call_sid],
      :call_direction => call_direction,
      :rest_api_enabled => false
    }
  end

  def get_call_variables(call_params)
    routing_instructions = get_routing_instructions(call_params)

    voice_request_url = call_params["voice_url"]
    voice_request_method = call_params["voice_method"]
    status_callback_url = call_params["status_callback_url"]
    status_callback_method = call_params["status_callback_method"]
    account_sid = call_params["account_sid"]
    auth_token = call_params["account_auth_token"]
    call_sid = call_params["sid"]
    caller_id = routing_instructions["source"] || call_params["from"] || default_caller_id
    destination = routing_instructions["destination"] || call_params["to"] || default_destination
    destination_host = routing_instructions["destination_host"] || default_destination_host
    gateway = routing_instructions["gateway"] || default_gateway
    dial_string_format = routing_instructions["dial_string_format"] || default_dial_string_format
    dial_string = routing_instructions["dial_string"] || default_dial_string || generate_dial_string(
      dial_string_format, destination, destination_host, gateway
    )
    disable_originate = routing_instructions["disable_originate"] || default_disable_originate

    {
      :voice_request_url => voice_request_url,
      :voice_request_method => voice_request_method,
      :status_callback_url => status_callback_url,
      :status_callback_method => status_callback_method,
      :account_sid => account_sid,
      :auth_token => auth_token,
      :call_sid => call_sid,
      :caller_id => caller_id,
      :destination => destination,
      :destination_host => destination_host,
      :gateway => gateway,
      :dial_string_format => dial_string_format,
      :dial_string => dial_string,
      :disable_originate => disable_originate
    }
  end

  def generate_dial_string(dial_string_format, destination, destination_host, gateway)
    dial_string_format.sub(
      /\%\{destination\}/, destination.to_s
    ).sub(
      /\%\{destination_host\}/, destination_host.to_s
    ).sub(
      /\%\{gateway\}/, gateway.to_s
    )
  end

  def default_destination
    ENV["AHN_SOMLENG_DEFAULT_DESTINATION"]
  end

  def default_destination_host
    ENV["AHN_SOMLENG_DEFAULT_DESTINATION_HOST"]
  end

  def default_dial_string
    ENV["AHN_SOMLENG_DEFAULT_DIAL_STRING"]
  end

  def default_gateway
    ENV["AHN_SOMLENG_DEFAULT_GATEWAY"]
  end

  def default_dial_string_format
    ENV["AHN_SOMLENG_DEFAULT_DIAL_STRING_FORMAT"] || DEFAULT_DIAL_STRING_FORMAT
  end

  def default_caller_id
    ENV["AHN_SOMLENG_DEFAULT_CALLER_ID"]
  end

  def default_disable_originate
    ENV["AHN_SOMLENG_DISABLE_ORIGINATE"]
  end
end
