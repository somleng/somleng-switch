SIPHeaders = Data.define(:call_sid, :account_sid, :carrier_sid, :call_direction, :billing_enabled, :billing_mode, :billing_category, :proxy_address, :external_profile) do
  def to_h
    {
      "X-Somleng-CallSid" => call_sid,
      "X-Somleng-AccountSid" => account_sid,
      "X-Somleng-CarrierSid" => carrier_sid,
      "X-Somleng-CallDirection" => call_direction,
      "X-Somleng-BillingEnabled" => billing_enabled,
      "X-Somleng-BillingMode" => billing_mode,
      "X-Somleng-BillingCategory" => billing_category,
      "X-Somleng-ProxyAddress" => proxy_address,
      "X-Somleng-ExternalProfile" => external_profile
    }.transform_values(&:to_s)
  end
end
