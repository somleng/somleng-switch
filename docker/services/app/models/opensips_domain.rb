class OpenSIPSDomain < ApplicationRecord
  attr_reader :ip

  def initialize(ip:, **options)
    super(**options)
    @ip = ip
  end

  def save!
    domain.insert(domain: ip, last_modified: Time.now) unless domain_exists?
  end

  def delete!
    domain.where(domain: ip).delete
  end

  private

  def domain_exists?
    domain.where(domain: ip).count.positive?
  end

  def domain
    @domain ||= database_connection.table(:domain)
  end
end
