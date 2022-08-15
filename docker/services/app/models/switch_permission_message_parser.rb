class SwitchPermissionMessageParser
  Message = Struct.new(
    :action,
    :source_ip,
    keyword_init: true
  )

  attr_reader :body

  def initialize(body)
    @body = JSON.parse(body)
  end

  def parse_message
    Message.new(
      action:,
      source_ip:
    )
  end

  private

  def action
    body.fetch("action")
  end

  def source_ip
    body.fetch("source_ip")
  end
end
