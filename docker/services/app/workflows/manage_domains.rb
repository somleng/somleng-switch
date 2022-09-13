class ManageDomains
  attr_reader :domains

  def initialize(domains:)
    @domains = domains
  end

  def create_domains
    database_connection.transaction do
      domains.each { |domain| create_domain!(domain:) }
    end
  end

  def delete_domains
    OpenSIPSDomain.where(domain: domains, database_connection:).delete
  end

  private

  def create_domain!(domain:)
    return if OpenSIPSDomain.exists?(domain:, database_connection:)

    OpenSIPSDomain.new(domain:, last_modified: Time.now, database_connection:).save!
  end

  def database_connection
    @database_connection ||= DatabaseConnections.find(:client_gateway)
  end
end
