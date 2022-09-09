class ApplicationRecord
  attr_reader :database_connection

  def initialize(database_connection:)
    @database_connection = database_connection
  end
end
