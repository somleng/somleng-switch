class HandleLogEvents < ApplicationWorkflow
  attr_reader :event

  def initialize(event:)
    @event = event
  end

  def call
    if opensips_log_groups.include?(event.log_group)
      HandleOpenSIPSLogEvent.call(event: OpenSIPSLogEventParser.new(event).parse_event)
    end
  end

  private

  def opensips_log_groups
    [ ENV.fetch("PUBLIC_GATEWAY_LOG_GROUP"), ENV.fetch("CLIENT_GATEWAY_LOG_GROUP") ]
  end
end
