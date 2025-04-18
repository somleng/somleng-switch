class FakeRedis < MockRedis
  Channel = Struct.new(:name, :subscribed, keyword_init: true) do
    def subscribed?
      subscribed
    end
  end

  class Subscription
    attr_reader :channels, :messages, :callbacks

    def initialize(**options)
      @channels = []
      @messages = []
      @callbacks = {}
      @poll_for_messages = options.fetch(:poll_for_messages, true)
    end

    def subscribe(&block)
      callbacks[:subscribe] = block
    end

    def unsubscribe(&block)
      callbacks[:unsubscribe] = block
    end

    def message(&block)
      callbacks[:message] = block
    end

    def publish(channel_name, message)
      channel = find_channel(channel_name)
      return if channel.blank?

      messages << [ channel, message ]
    end

    def find_channel(channel_name)
      channels.find { |channel| File.fnmatch(channel_name, channel.name) }
    end

    def subscribe!(*channel_names)
      Array(channel_names).each do |channel_name|
        channels << Channel.new(name: channel_name, subscribed: true)
      end
    end

    def unsubscribe!(*channel_names)
      if Array(channel_names).empty?
        subscribed_channels.each do |channel|
          channel.subscribed = false
          on_unsubscribe
        end
      else
        Array(channel_names).each do |channel_name|
          channel = find_channel(channel_name)
          next if channel.blank?
          next unless channel.subscribed?

          channel.subscribed = false
          on_unsubscribe
        end
      end
    end

    def on_subscribe
      return unless callbacks.key?(:subscribe)

      subscribed_channels.each do |channel|
        callbacks.fetch(:subscribe).call(channel.name, subscribed_channels.size)
      end
    end

    def poll_for_messages
      return unless @poll_for_messages

      loop do
        break if subscribed_channels.empty?
        next unless callbacks.key?(:message)

        messages.each do |(channel, message)|
          next unless channel.subscribed?

          callbacks.fetch(:message).call(channel.name, message.respond_to?(:call) ? message.call(channel.name) : message)
        end
      end
    end

    private

    def subscribed_channels
      channels.find_all(&:subscribed?)
    end

    def on_unsubscribe
      callbacks.fetch(:unsubscribe).call(channel.name, subscribed_channels.size) if callbacks.key?(:unsubscribe)
    end
  end

  attr_reader :subscription_options, :future_messages, :subscriptions

  def initialize(subscription_options: {})
    super()
    @subscription_options = subscription_options
    @future_messages = []
    @subscriptions = []
  end

  def publish(channel_name, message)
    find_subscription(channel_name)&.publish(channel_name, message)
  end

  def subscribe(*channel_names, &)
    subscription = build_subscription
    subscription.subscribe!(*channel_names)
    yield(subscription)

    subscription.on_subscribe
    future_messages.each do |(channel, message)|
      subscription.publish(channel, message)
    end
    subscription.poll_for_messages
  end

  def unsubscribe(*channel_names)
    if Array(channel_names).empty?
      subscriptions.each(&:unsubscribe!)
    else
      find_subscription(*channel_names)&.unsubscribe!(*channel_names)
    end
  end

  def publish_on_subscribe(channel_name, message)
    future_messages << [ channel_name, message ]
  end

  def flushall
    subscriptions.clear
    future_messages.clear
    super
  end

  private

  def find_subscription(*channel_names)
    subscriptions.find do |subscription|
      Array(channel_names).each do |channel_name|
        return subscription if subscription.find_channel(channel_name)
      end
    end
  end

  def build_subscription
    subscription = Subscription.new(**subscription_options)
    subscriptions << subscription
    subscription
  end
end

AppSettings.redis_client = -> { FakeRedis.new }

RSpec.configure do |config|
  config.before do
    AppSettings.redis.with { |redis| redis.flushall }
  end
end
