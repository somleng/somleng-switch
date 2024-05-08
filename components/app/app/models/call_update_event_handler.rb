
class CallUpdateEventHandler
  CHANNEL_PREFIX = "call_updates".freeze

  class Event
    attr_reader :call_id, :voice_url, :voice_method, :twiml

    def initialize(**params)
      @call_id = params.fetch(:call_id)
      @voice_url = params[:voice_url]
      @voice_method = params[:voice_method]
      @twiml = params[:twiml]
    end

    def self.parse(payload)
      message = JSON.parse(payload)

      new(
        call_id: message.fetch("id"),
        voice_url: message["voice_url"],
        voice_method: message["voice_method"],
        twiml: message["twiml"]
      )
    end

    def serialize
      JSON.generate(
        {
          id: call_id,
          voice_url:,
          voice_method:,
          twiml:
        }.compact
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

  def build_event(**)
    Event.new(**)
  end

  def perform_later(event)
    queue.push(event)
  end

  def perform_now(event)
    throw(
      :redirect,
      {
        url: event.voice_url,
        http_method: event.voice_method,
        twiml: event.twiml
      }.compact
    )
  end

  def perform_queued
    queue.each do |event|
      perform_now(event)
    end
  end

  def fake_event(**params)
    Event.new(
      call_id: SecureRandom.uuid,
      **params
    )
  end
end
