class ECSEventParser
  Event = Struct.new(
    :task_running?,
    :task_stopped?,
    :eni_attached?,
    :eni_deleted?,
    :eni_private_ip,
    :group,
    keyword_init: true
  )

  attr_reader :event

  def initialize(event)
    @event = event
  end

  def parse_event
    Event.new(
      task_running?: task_running?,
      task_stopped?: task_stopped?,
      eni_attached?: eni_attached?,
      eni_deleted?: eni_deleted?,
      eni_private_ip:,
      group:
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

  def eni_attached?
    return false if eni.nil?

    eni.fetch("status") == "ATTACHED"
  end

  def eni_deleted?
    return false if eni.nil?

    eni.fetch("status") == "DELETED"
  end

  def group
    detail.fetch("group")
  end

  def eni_private_ip
    return if eni.nil?

    eni.fetch("details").find { |detail| detail.fetch("name") == "privateIPv4Address" }.fetch("value")
  end

  def eni
    attachments.find { |attachment| attachment.fetch("type") == "eni" }
  end

  def detail
    event.fetch("detail")
  end

  def attachments
    detail.fetch("attachments")
  end
end
