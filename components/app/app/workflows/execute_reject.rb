class ExecuteReject < ExecuteTwiMLVerb
  def call
    reject(verb.reason == "busy" ? :busy : :decline)
  end

  private

  def reject(reason, headers = {})
    context.reject(reason, call_properties.sip_headers.to_h.reverse_merge(headers))
  end
end
