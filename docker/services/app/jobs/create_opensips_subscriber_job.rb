class CreateOpenSIPSSubscriberJob
  attr_reader :username, :md5_password, :sha256_password, :sha512_password

  def initialize(options)
    options.transform_keys!(&:to_sym)
    @username = options.fetch(:username)
    @md5_password = options.fetch(:md5_password)
    @sha256_password = options.fetch(:sha256_password)
    @sha512_password = options.fetch(:sha512_password)
  end

  def call
    return if OpenSIPSSubscriber.exists?(username:, database_connection:)

    OpenSIPSSubscriber.new(
      username:,
      ha1: md5_password,
      ha1_sha256: sha256_password,
      ha1_sha512t256: sha512_password,
      database_connection:
    ).save!
  end

  private

  def database_connection
    @database_connection ||= DatabaseConnections.find(:client_gateway)
  end
end
