require "encrypted_credentials/app_settings"

AppSettings = EncryptedCredentials::AppSettings.new(config_directory: File.expand_path(__dir__))
