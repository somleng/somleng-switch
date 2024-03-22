class FakeRedis < MockRedis
  class NullSubscription
    def message(&)
      sleep
    end

    def unsubscribe; end
  end

  class Subscription
    attr_reader :channel, :messages

    def initialize(channel)
      @channel = channel
      @messages = []
    end

    def message(&)
      messages.each do |message|
        yield(channel, message)
      end

      poll_for_messages
      foo = [ "bar", "baz" ]
    end

    def publish(message)
      messages << message
    end

    def unsubscribe
      @unsubscribed = true
    end

    private

    def poll_for_messages
      loop do
        break if unsubscribed?

        sleep(1)
      end
    end

    def unsubscribed?
      @unsubscribed
    end
  end

  def subscribe(channel, &)
    yield(find_subscription(channel))
  end

  def unsubscribe(channel)
    find_subscription(channel).unsubscribe
    subscriptions.delete(channel)
  end

  def publish_later(channel, message)
    subscriptions[channel] ||= Subscription.new(channel)
    subscriptions[channel].publish(message)
  end

  private

  def subscriptions
    @subscriptions ||= {}
  end

  def find_subscription(channel)
    subscriptions.fetch(channel) { NullSubscription.new }
  end
end

AppSettings.redis_client = -> { FakeRedis.new }
