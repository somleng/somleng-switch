require "encrypted_credentials/app_settings"
require "encrypted_credentials/encrypted_file"
require "connection_pool"

AppSettings = Class.new(EncryptedCredentials::AppSettings) do
  attr_writer :redis_client

  def initialize(**)
    super(
      file: Pathname(File.expand_path("app_settings.yml", __dir__)),
      encrypted_file: EncryptedCredentials::EncryptedFile.new(
        file: Pathname(File.expand_path("credentials.yml.enc", __dir__))
      ),
      **
    )
  end

  def redis
    @redis ||= ConnectionPool.new(size: fetch(:redis_pool_size)) { redis_client.call }
  end

  def redis_client
    @redis_client ||= -> { Redis.new(url: fetch(:redis_url)) }
  end
end.new
