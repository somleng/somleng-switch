class FakeRedis < MockRedis
  class DefaultSubscription
    def message(&)
      sleep
    end

    def subscribe(&)
      yield
    end

    def unsubscribe(&)
      yield
    end
  end

  class Subscription < DefaultSubscription
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
    end

    def publish(message)
      messages << message
    end

    def unsubscribe!
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
    find_subscription(channel).unsubscribe!
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
    subscriptions.fetch(channel) { DefaultSubscription.new }
  end
end

AppSettings.redis_client = -> { FakeRedis.new }
