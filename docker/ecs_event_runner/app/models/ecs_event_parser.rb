class ECSEventParser
  Event = Struct.new(:task_running?, :task_stopped?, :eni_private_ip, :task_family, keyword_init: true)

  attr_reader :event

  def initialize(event)
    @event = event
  end

  def parse_event
    Event.new(
      task_running?: task_running?,
      task_stopped?: task_stopped?,
      eni_private_ip:,
      task_family:
    )
  end

  private

  def last_status
    detail.fetch("lastStatus")
  end

  def task_running?
    last_status == "RUNNING"
  end

  def task_stopped?
    last_status == "STOPPED"
  end

  def task_family
    group.delete_prefix("family:") if group.start_with?("family:")
  end

  def group
    detail.fetch("group")
  end

  def eni_private_ip
    eni.fetch("details").find { |detail| detail.fetch("name") == "privateIPv4Address" }.fetch("value")
  end

  def eni
    attachments.find { |attachment| attachment.fetch("type") == "eni" && attachment.fetch("status") == "ATTACHED" }
  end

  def detail
    event.fetch("detail")
  end

  def attachments
    detail.fetch("attachments")
  end
end
