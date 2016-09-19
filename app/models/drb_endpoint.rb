class DrbEndpoint
  DEFAULT_DIAL_STRING_FORMAT = "%{destination}"

  attr_accessor :call_params, :destination, :destination_host,
                :caller_id, :dial_string_format, :dial_string, :gateway,
                :voice_request_url, :voice_request_method,
                :status_callback_url, :status_callback_method,
                :call_sid, :account_sid, :auth_token, :disable_originate

  def initiate_outbound_call!(call_json)
    logger.info("Receiving DRb request: #{call_json}")
    self.call_params = JSON.parse(call_json)
    setup_call_variables

    call_args = [
      dial_string,
      {
        :from => caller_id,
        :controller => CallController,
        :controller_metadata => controller_metadata
      }
    ]

    if originate_call?
      logger.info("Initiating outbound call with: #{call_args}")
      Adhearsion::OutboundCall.originate(*call_args).id
    end
  end

  private

  def originate_call?
    disable_originate.to_i != 1
  end

  def routing_instructions
    call_params["routing_instructions"] || {}
  end

  def controller_metadata
    {
      :voice_request_url => voice_request_url,
      :voice_request_method => voice_request_method,
      :status_callback_url => status_callback_url,
      :status_callback_method => status_callback_method,
      :account_sid => account_sid,
      :auth_token => auth_token,
      :call_sid => call_sid,
      :call_direction => :outbound_api
    }
  end

  def setup_call_variables
    self.voice_request_url = call_params["voice_url"]
    self.voice_request_method = call_params["voice_method"]
    self.status_callback_url = call_params["status_callback_url"]
    self.status_callback_method = call_params["status_callback_method"]
    self.account_sid = call_params["account_sid"]
    self.auth_token = call_params["account_auth_token"]
    self.call_sid = call_params["sid"]

    self.caller_id = routing_instructions["source"] || call_params["from"] || default_caller_id
    self.destination = routing_instructions["destination"] || call_params["to"] || default_destination
    self.destination_host = routing_instructions["destination_host"] || default_destination_host
    self.gateway = routing_instructions["gateway"] || default_gateway
    self.dial_string_format = routing_instructions["dial_string_format"] || default_dial_string_format
    self.dial_string = routing_instructions["dial_string"] || default_dial_string || generate_dial_string
    self.disable_originate = routing_instructions["disable_originate"] || default_disable_originate
  end

  def generate_dial_string
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
