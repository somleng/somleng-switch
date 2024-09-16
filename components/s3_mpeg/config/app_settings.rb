require "yaml"
require "erb"
require "pathname"
require "encrypted_credentials"

class AppSettings
  DEFAULT_SETTINGS_PATH = Pathname(File.expand_path("app_settings.yml", __dir__))

  class << self
    attr_reader :app_settings

    def fetch(key)
      settings.fetch(key.to_s)
    end

    def env
      ENV.fetch("APP_ENV", "development")
    end

    def [](key)
      settings[key.to_s]
    end

    def credentials
      @credentials ||= EncryptedCredentials::EncryptedFile.new.credentials.fetch(env, {})
    end

    private

    def settings
      @settings ||= begin
        data = YAML.load(DEFAULT_SETTINGS_PATH.read, aliases: true).fetch(env, {})
        YAML.load(ERB.new(data.to_yaml).result)
      end
    end
  end
end
