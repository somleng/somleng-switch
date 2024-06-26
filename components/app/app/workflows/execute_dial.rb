class ExecuteDial < ExecuteTwiMLVerb
  DIAL_CALL_STATUSES = {
    no_answer: "no-answer",
    answer: "completed",
    timeout: "no-answer",
    error: "failed",
    busy: "busy",
    in_progress: "in-progress",
    ringing: "ringing"
  }.freeze

  def call
    answer!
    phone_calls = create_outbound_calls
    dial_status = context.dial(build_dial_params(phone_calls))

    return if verb.action.blank?

    redirect(build_callback_params(dial_status))
  end

  private

  def build_dial_params(phone_calls)
    phone_calls.each_with_object({}) do |phone_call, result|
      dial_string, from = build_dial_string(phone_call)

      result[dial_string.to_s] = {
        from:,
        for: verb.timeout.seconds,
        headers: SIPHeaders.new(
          call_sid: phone_call.sid,
          account_sid: phone_call.account_sid
        ).to_h
      }.compact
    end
  end

  def create_outbound_calls
    call_platform_client.create_outbound_calls(
      destinations: verb.nested_nouns.map { |nested_noun| nested_noun.content.strip },
      parent_call_sid: call_properties.call_sid,
      from: verb.caller_id
    )
  end

  def redirect(params)
    throw(
      :redirect,
      {
        url: verb.action,
        http_method: verb.method,
        params:
      }
    )
  end

  def build_callback_params(dial_status)
    result = {}
    result["DialCallStatus"] = DIAL_CALL_STATUSES.fetch(dial_status.result)

    if (joined_call = find_joined_call(dial_status))
      result["DialCallSid"] = joined_call.id
      result["DialCallDuration"] = dial_status.joins[joined_call].duration.to_i
    end

    result
  end

  def find_joined_call(dial_status)
    dial_status.joins.find do |outbound_call, join_status|
      return outbound_call if join_status.result == :joined
    end
  end

  def build_dial_string(phone_call_response)
    if phone_call_response.address.present?
      DialString.new(address: phone_call_response.address)
    else
      dial_string = DialString.new(phone_call_response.routing_parameters)
      [ dial_string, dial_string.format_number(phone_call_response.from) ]
    end
  end
end
