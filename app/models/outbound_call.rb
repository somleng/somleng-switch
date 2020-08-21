class OutboundCall
  DEFAULT_DIAL_STRING_FORMAT = "sofia/%{dial_string_path}".freeze
  NUMBER_NORMALIZER = Adhearsion::Twilio::Util::NumberNormalizer.new.freeze

  attr_reader :call_params

  def initialize(call_params:, logger: Logger.new(STDOUT))
    @call_params = call_params
  end

  def initiate
    return if routing_instructions["disable_originate"].to_i == 1

    Adhearsion::OutboundCall.originate(
      dial_string,
      from: caller_id,
      controller: CallController,
      controller_metadata:{
        voice_request_url: call_params["voice_url"],
        voice_request_method: call_params["voice_method"],
        account_sid: call_params["account_sid"],
        auth_token: call_params["account_auth_token"],
        call_sid: call_params["sid"],
        adhearsion_twilio_from: NUMBER_NORMALIZER.normalize(caller_id),
        adhearsion_twilio_to: NUMBER_NORMALIZER.normalize(destination),
        direction: call_params["direction"],
        api_version: call_params["api_version"],
        rest_api_enabled: false
      }
    )
  end

  private

  def routing_instructions
    call_params.fetch("routing_instructions", {})
  end

  def caller_id
    routing_instructions.fetch("source") { call_params["from"] }
  end

  def destination
    routing_instructions.fetch("destination") { call_params["to"] }
  end

  def dial_string
    routing_instructions.fetch("dial_string") do
      format = routing_instructions.fetch("dial_string_format") { DEFAULT_DIAL_STRING_FORMAT }

      format.sub(
        /\%\{destination\}/, destination.to_s
      ).sub(
        /\%\{gateway_type\}/, routing_instructions["gateway_type"].to_s
      ).sub(
        /\%\{destination_host\}/, routing_instructions["destination_host"].to_s
      ).sub(
        /\%\{gateway\}/, routing_instructions["gateway"].to_s
      ).sub(
        /\%\{address\}/, routing_instructions["address"].to_s
      ).sub(
        /\%\{dial_string_path\}/, routing_instructions["dial_string_path"].to_s
      )
    end
  end
end
