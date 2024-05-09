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
    dial_status = context.dial(build_dial_strings)
    return if verb.action.blank?

    redirect(build_callback_params(dial_status))
  end

  private

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

  def build_dial_strings
    verb.nested_nouns.each_with_object(Hash.new({})) do |nested_noun, result|
      dial_string, from = build_dial_string(nested_noun)

      result[dial_string.to_s] = { from:, for: verb.timeout.seconds }.compact
    end
  end

  def build_dial_string(nested_noun)
    dial_content = nested_noun.content.strip

    if dial_to_number?(nested_noun)
      dial_string = DialString.new(build_routing_parameters(dial_content))
      [ dial_string, dial_string.format_number(caller_id) ]
    elsif dial_to_sip?(nested_noun)
      DialString.new(address: dial_content.delete_prefix("sip:"))
    end
  end

  def dial_to_number?(nested_noun)
    nested_noun.text? || nested_noun.name == "Number"
  end

  def dial_to_sip?(nested_noun)
    nested_noun.name == "Sip"
  end

  def caller_id
    return verb.caller_id if verb.caller_id.present?

    call_properties.inbound? ? call_properties.from : call_properties.to
  end

  def build_routing_parameters(number)
    call_platform_client.build_routing_parameters(
      phone_number: number,
      account_sid: call_properties.account_sid
    )
  end
end
