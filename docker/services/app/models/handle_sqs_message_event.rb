class HandleSQSMessageEvent < ApplicationWorkflow
  attr_reader :event

  def initialize(event:)
    @event = event
  end

  def call
    event.records.each do |record|
      case record.event_source_arn
      when ENV.fetch("SWITCH_PERMISSIONS_QUEUE_ARN")
        handle_permission_message(record)
      end
    end
  end

  private

  def handle_permission_message(record)
    message = SwitchPermissionMessageParser.new(record.body).parse_message
    address = build_opensips_address(message)

    case message.action
    when "add_permission"
      address.save!
    when "remove_permission"
      address.delete!
    end
  end

  def build_opensips_address(message)
    OpenSIPSAddress.new(ip: message.source_ip)
  end
end
