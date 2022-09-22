class DeleteOpenSIPSSubscriberJob
  attr_reader :username

  def initialize(options)
    options.transform_keys!(&:to_sym)
    @username = options.fetch(:username)
  end

  def call
    OpenSIPSSubscriber.where(username:, database_connection:).delete
  end

  private

  def database_connection
    DatabaseConnections.find(:client_gateway)
  end
end
