SIPHeaders = Data.define(:call_sid, :account_sid, :carrier_sid, :billing_mode) do
  def to_h
    {
      "X-Somleng-CallSid" => call_sid,
      "X-Somleng-AccountSid" => account_sid,
      "X-Somleng-CarrierSid" => carrier_sid,
      "X-Somleng-BillingMode" => billing_mode
    }
  end
end
