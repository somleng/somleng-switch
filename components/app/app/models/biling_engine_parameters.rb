BillingEngineParameters = Data.define(:charging_mode) do
  def to_h
    CGRates::ChannelVariables.new(charging_mode:).to_h
  end
end
