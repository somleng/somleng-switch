require "encrypted_credentials/encrypted_environment_variables"

unless %w[development test].include?(AppSettings.env)
  EncryptedCredentials::EncryptedEnvironmentVariables.new.decrypt
end
