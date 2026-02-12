SIPHeaders = Data.define(:call_sid, :account_sid, :carrier_sid, :billing_enabled, :billing_mode, :billing_category) do
  def to_h
    {
      "X-Somleng-CallSid" => call_sid,
      "X-Somleng-AccountSid" => account_sid,
      "X-Somleng-CarrierSid" => carrier_sid,
      "X-Somleng-BillingEnabled" => billing_enabled,
      "X-Somleng-BillingMode" => billing_mode,
      "X-Somleng-BillingCategory" => billing_category
    }
  end
end
