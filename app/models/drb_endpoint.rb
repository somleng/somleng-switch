class DrbEndpoint
  attr_accessor :call_params, :destination_host, :number_to_dial,
                :dial_string_format, :dial_string,
                :voice_request_url, :voice_request_method,
                :status_callback_url, :status_callback_method

  def initiate_outbound_call!(call_json)
    self.call_params = JSON.parse(call_json)
    setup_call_variables
    Adhearsion::OutboundCall.originate(dial_string, :controller_metadata => controller_metadata)
  end

  private

  def controller_metadata
    {
      :voice_request_url => voice_request_url,
      :voice_request_method => voice_request_method,
      :status_callback_url => status_callback_url,
      :status_callback_method => status_callback_method
    }
  end

  def setup_call_variables
    self.destination_host = call_params["destination_host"] || default_destination_host
    self.number_to_dial = call_params["number_to_dial"] || default_number_to_dial
    self.dial_string_format = call_params["dial_string_format"] || default_dial_string_format
    self.dial_string = call_params["dial_string"] || default_dial_string || generate_dial_string
    self.voice_request_url = call_params["voice_url"]
    self.voice_request_method = call_params["voice_method"]
    self.status_callback_url = call_params["status_callback_url"]
    self.status_callback_method = call_params["status_callback_method"]
  end

  def generate_dial_string
    dial_string_format.sub(
      /\%\{number_to_dial\}\%/, number_to_dial
    ).sub(
      /\%\{destination_host\}\%/, destination_host
    )
  end

  def default_number_to_dial
    ENV["AHN_SOMLENG_DEFAULT_NUMBER_TO_DIAL"]
  end

  def default_destination_host
    ENV["AHN_SOMLENG_DEFAULT_DESTINATION_HOST"]
  end

  def default_dial_string
    ENV["AHN_SOMLENG_DEFAULT_DIAL_STRING"]
  end

  def default_dial_string_format
    ENV["AHN_SOMLENG_DEFAULT_DIAL_STRING_FORMAT"]
  end
end
