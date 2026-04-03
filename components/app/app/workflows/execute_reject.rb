class ExecuteReject < ExecuteTwiMLVerb
  def call
    reject(verb.reason == "busy" ? :busy : :decline)
  end

  private

  def reject(reason)
    context.reject(reason, call_properties.sip_headers.response_headers)
  end
end
