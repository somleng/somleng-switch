require "yaml"
require "erb"

class AppSettings
  DEFAULT_SETTINGS_PATH = Pathname(File.expand_path("app_settings.yml", __dir__))

  class << self
    attr_reader :app_settings

    def fetch(key)
      settings.fetch(key.to_s)
    end

    def [](key)
      settings[key.to_s]
    end

    def credentials
      @credentials ||= EncryptedCredentials::EncryptedFile.new.credentials.fetch(app_env)
    end

    private

    def settings
      @settings ||= begin
        data = YAML.load(DEFAULT_SETTINGS_PATH.read, aliases: true).fetch(app_env)
        YAML.load(ERB.new(data.to_yaml).result)
      end
    end

    def app_env
      ENV.fetch("APP_ENV", "development")
    end
  end
end
