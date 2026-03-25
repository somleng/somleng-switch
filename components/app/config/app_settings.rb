require "encrypted_credentials/app_settings"
require "connection_pool"
require "socket"

app_settings = Class.new(EncryptedCredentials::AppSettings) do
  attr_writer :redis_client

  def redis
    @redis ||= ConnectionPool.new(size: fetch(:redis_pool_size)) { redis_client.call }
  end

  def redis_client
    @redis_client ||= -> { Redis.new(url: fetch(:redis_url)) }
  end

  def host_ip
    Socket.ip_address_list.find { |interface| interface.ipv4_private? }.ip_address
  end
end

AppSettings = app_settings.new(config_directory: File.expand_path(__dir__))
