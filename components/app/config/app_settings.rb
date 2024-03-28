require "yaml"
require "erb"
require "connection_pool"

class AppSettings
  DEFAULT_SETTINGS_PATH = Pathname(File.expand_path("app_settings.yml", __dir__))

  class << self
    attr_reader :app_settings
    attr_writer :redis_client

    def redis
      @redis ||= ConnectionPool.new(size: fetch(:redis_pool_size)) { redis_client.call }
    end

    def redis_client
      @redis_client ||= -> { Redis.new(url: fetch(:redis_url)) }
    end

    def fetch(key)
      settings.fetch(key.to_s)
    end

    def [](key)
      settings[key.to_s]
    end

    def env
      ENV.fetch("APP_ENV", "development")
    end

    def credentials
      @credentials ||= EncryptedCredentials::EncryptedFile.new.credentials.fetch(env)
    end

    private

    def settings
      @settings ||= begin
        data = YAML.load(DEFAULT_SETTINGS_PATH.read, aliases: true).fetch(env)
        YAML.load(ERB.new(data.to_yaml).result)
      end
    end
  end
end
