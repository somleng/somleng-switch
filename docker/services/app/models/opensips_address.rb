class OpenSIPSAddress < ApplicationRecord
  attr_reader :ip

  def initialize(ip:)
    @ip = ip
  end

  def save!
    address.insert(ip:) unless address_exists?
  end

  def delete!
    address.where(ip:).delete
  end

  private

  def address_exists?
    address.where(ip:).count.positive?
  end

  def address
    @address ||= database_connection.table(:address)
  end
end
