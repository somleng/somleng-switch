SIPHeaders = Struct.new(:call_sid, :account_sid, keyword_init: true) do
  def to_h
    {
      "X-Somleng-CallSid" => call_sid,
      "X-Somleng-AccountSid" => account_sid
    }
  end
end
