class ApplicationRecord
  def database_connection
    @database_connection ||= DatabaseConnection.new(db_name: ENV.fetch("OPENSIPS_DB_NAME"))
  end
end
