
class CallUpdateEventHandler
  CHANNEL_PREFIX = "call_updates".freeze

  class Event
    attr_reader :payload

    def initialize(**params)
      @payload = params.fetch(:payload)
    end

    def self.parse(payload)
      message = JSON.parse(payload)

      new(
        payload: message
      )
    end
  end

  attr_reader :queue

  def initialize
    @queue = []
  end

  def channel_for(call_id)
    "#{CHANNEL_PREFIX}:#{call_id}"
  end

  def handle_events_for?(channel, call_id)
    channel == channel_for(call_id)
  end

  def parse_event(message)
    Event.parse(message)
  end

  def perform_later(event)
    queue.push(event)
  end

  def perform_now(event)
  end

  def perform_queued
    queue.each do |event|
      perform_now(event)
    end
  end

  def fake_event(**params)
    Event.new(
      payload: {},
      **params
    )
  end
end
