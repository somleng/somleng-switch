class FakeRedis < MockRedis
  class Channel
    attr_reader :messages
    attr_accessor :name, :subscribed

    def initialize(name:, messages: [])
      @name = name
      @messages = messages
    end

    def subscribed?
      @subscribed
    end
  end

  class Subscription
    attr_reader :channels, :messages

    def initialize(*channel_names, **options)
      @channels = []
      @messages = []
      @poll_for_messages = options.fetch(:poll_for_messages, true)
      channel_names.each do |channel_name|
        channels << Channel.new(name: channel_name)
      end
    end

    def subscribe(&)
      channels.each do |channel|
        yield(channel.name, channels.size)
      end
    end

    def unsubscribe(&)
      yield
    end

    def message(&)
      messages.each do |(channel, message)|
        next unless channel.subscribed?

        yield(channel.name, message.respond_to?(:call) ? message.call(channel.name) : message)
      end

      poll_for_messages if @poll_for_messages
    end

    def publish(channel_name, message)
      channel = find_channel(channel_name)
      if channel.blank?
        channel = Channel.new(name: channel_name)
        channels << channel
      end
      channel.messages << message
      messages << [ channel, message ]
    end

    def find_channel(channel_name)
      channels.find { |channel| File.fnmatch(channel.name, channel_name) }
    end

    def subscribe!(*channel_names)
      Array(channel_names).each do |channel_name|
        channel = find_channel(channel_name)

        if channel.blank?
          channel = Channel.new(name: channel_name)
          channels << channel
        end

        channel.name = channel_name
        channel.subscribed = true
      end
    end

    def unsubscribe!(*channel_names)
      if Array(channel_names).empty?
        channels.each do |channel|
          channel.subscribed = false
        end
      else
        Array(channel_names).each do |channel_name|
          channel = find_channel(channel_name)
          channel.subscribed = false if channel.present?
        end
      end
    end

    private

    def poll_for_messages
      loop do
        break if channels.none?(&:subscribed?)

        sleep(1)
      end
    end
  end

  attr_reader :subscription_options

  def initialize(subscription_options: {})
    super()
    @subscription_options = subscription_options
  end

  def publish(channel_name, message)
    subscription = find_or_initialize_subscription(channel_name)
    subscription.publish(channel_name, message)
  end

  def subscribe(*channel_names, &)
    subscription = find_or_initialize_subscription(*channel_names)
    subscription.subscribe!(*channel_names)
    yield(subscription)
  end

  def unsubscribe(*channel_names)
    if Array(channel_names).empty?
      subscriptions.each(&:unsubscribe!)
    else
      subscription = find_or_initialize_subscription(*channel_names)
      subscription.unsubscribe!(*channel_names)
    end
  end

  def publish_later(channel_name, message)
    publish(channel_name, message)
  end

  def flushall
    subscriptions.clear
    super
  end

  private

  def subscriptions
    @subscriptions ||= []
  end

  def find_or_initialize_subscription(*channel_names)
    result = subscriptions.find(-> { Subscription.new(*channel_names, **subscription_options) }) do |subscription|
      Array(channel_names).each do |channel_name|
        return subscription if subscription.find_channel(channel_name)
      end
    end
    subscriptions << result unless subscriptions.include?(result)
    result
  end
end

AppSettings.redis_client = -> { FakeRedis.new }

RSpec.configure do |config|
  config.before(:each) do
    AppSettings.redis.with { |redis| redis.flushall }
  end
end
