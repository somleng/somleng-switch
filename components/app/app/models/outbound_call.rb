class OutboundCall
  attr_reader :call_params

  def initialize(call_params)
    @call_params = call_params
  end

  def initiate
    dial_string = DialString.new(call_params.fetch("routing_parameters"))
    call_properties = BuildCallProperties.call(call_params)
    sip_headers = call_properties.sip_headers

    Adhearsion::OutboundCall.originate(
      dial_string.to_s,
      from: dial_string.format_number(call_params.fetch("from")),
      controller: CallController,
      controller_metadata: {
        call_properties:
      },
      headers: build_call_headers(sip_headers)
    )
  end

  private

  def build_call_headers(sip_headers)
    return sip_headers.to_h unless CallPlatform.configuration.stub_responses

    sip_headers.to_h.merge(call_params.fetch("test_headers", {}))
  end
end
