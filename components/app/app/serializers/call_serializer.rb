require "socket"

class CallSerializer
  attr_reader :object

  def initialize(object)
    @object = object
  end

  def id
    object.id
  end

  def host
    Socket.ip_address_list.find { |interface| interface.ipv4_private? }.ip_address
  end

  def to_h
    {
      id:,
      host:
    }
  end
end
