require "encrypted_credentials/app_settings"
require "encrypted_credentials/encrypted_file"

AppSettings = Class.new(EncryptedCredentials::AppSettings) do
  def initialize(**)
    super(
      file: Pathname(File.expand_path("app_settings.yml", __dir__)),
      encrypted_file: EncryptedCredentials::EncryptedFile.new(
        file: Pathname(File.expand_path("credentials.yml.enc", __dir__))
      ),
      **
    )
  end
end.new
