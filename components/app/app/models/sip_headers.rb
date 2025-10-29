SIPHeaders = Data.define(:call_sid, :account_sid, :carrier_sid) do
  def to_h
    {
      "X-Somleng-CallSid" => call_sid,
      "X-Somleng-AccountSid" => account_sid,
      "X-Somleng-CarrierSid" => carrier_sid
    }
  end
end
