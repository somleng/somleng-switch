class DrbEndpoint
  # Do not use instance variables in this class!
  # If an instance variable is set,
  # the next time this DrbEndpoint is invoked it will use the previous instance variable
  # DRb is not thread safe!

  DEFAULT_DIAL_STRING_FORMAT = "%{destination}".freeze

  def initiate_outbound_call!(call_json)
    logger.info("Receiving DRb request: #{call_json}")
    call_params = JSON.parse(call_json)
    call_variables = get_call_variables(call_params)

    call_args = [
      call_variables[:dial_string],
      {
        from: call_variables[:caller_id],
        controller: CallController,
        controller_metadata: controller_metadata(call_variables)
      }
    ]

    return nil if call_variables[:disable_originate].to_i == 1

    logger.info("Initiating outbound call with: #{call_args}")
    Adhearsion::OutboundCall.originate(*call_args).id
  end

  private

  def get_routing_instructions(call_params)
    call_params["routing_instructions"] || {}
  end

  def controller_metadata(call_variables)
    {
      voice_request_url: call_variables[:voice_request_url],
      voice_request_method: call_variables[:voice_request_method],
      account_sid: call_variables[:account_sid],
      auth_token: call_variables[:auth_token],
      call_sid: call_variables[:call_sid],
      adhearsion_twilio_to: call_variables[:adhearsion_twilio_to],
      adhearsion_twilio_from: call_variables[:adhearsion_twilio_from],
      direction: call_variables[:direction],
      api_version: call_variables[:api_version],
      rest_api_enabled: false
    }
  end

  def get_call_variables(call_params)
    routing_instructions = get_routing_instructions(call_params)

    voice_request_url = call_params.fetch("voice_url") { nil }
    voice_request_method = call_params.fetch("voice_method") { nil }
    account_sid = call_params.fetch("account_sid") { nil }
    auth_token = call_params.fetch("account_auth_token") { nil }
    call_sid = call_params.fetch("sid") { nil }
    direction = call_params.fetch("direction") { nil }
    api_version = call_params.fetch("api_version") { nil }
    caller_id = routing_instructions.fetch("source") { call_params.fetch("from") { nil } }
    address = routing_instructions.fetch("address") { nil }
    destination = routing_instructions.fetch("destination") { call_params.fetch("to") { nil } }
    destination_host = routing_instructions.fetch("destination_host") { nil }
    gateway = routing_instructions.fetch("gateway") { nil }
    gateway_type = routing_instructions.fetch("gateway_type") { nil }
    dial_string_path = routing_instructions.fetch("dial_string_path") { nil }
    dial_string_format = routing_instructions.fetch("dial_string_format") { DEFAULT_DIAL_STRING_FORMAT }
    dial_string = routing_instructions.fetch("dial_string") do
      generate_dial_string(
        dial_string_format, destination, gateway_type,
        destination_host, gateway, address, dial_string_path
      )
    end
    disable_originate = routing_instructions.fetch("disable_originate") { nil }

    number_normalizer = Adhearsion::Twilio::Util::NumberNormalizer.new
    adhearsion_twilio_from = number_normalizer.normalize(caller_id)
    adhearsion_twilio_to = number_normalizer.normalize(destination)

    {
      voice_request_url: voice_request_url,
      voice_request_method: voice_request_method,
      account_sid: account_sid,
      auth_token: auth_token,
      call_sid: call_sid,
      caller_id: caller_id,
      destination: destination,
      destination_host: destination_host,
      gateway: gateway,
      dial_string_format: dial_string_format,
      dial_string: dial_string,
      adhearsion_twilio_from: adhearsion_twilio_from,
      adhearsion_twilio_to: adhearsion_twilio_to,
      direction: direction,
      api_version: api_version,
      disable_originate: disable_originate
    }
  end

  def generate_dial_string(dial_string_format, destination, gateway_type, destination_host, gateway, address, dial_string_path)
    dial_string_format.sub(
      /\%\{destination\}/, destination.to_s
    ).sub(
      /\%\{gateway_type\}/, gateway_type.to_s
    ).sub(
      /\%\{destination_host\}/, destination_host.to_s
    ).sub(
      /\%\{gateway\}/, gateway.to_s
    ).sub(
      /\%\{address\}/, address.to_s
    ).sub(
      /\%\{dial_string_path\}/, dial_string_path.to_s
    )
  end
end
