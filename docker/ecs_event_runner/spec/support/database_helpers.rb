module DatabaseHelpers
  def opensips_database_connection
    @opensips_database_connection ||= TestDatabaseConnection.new(
      db_name: ENV.fetch("OPENSIPS_DB_NAME")
    )
  end

  def setup_database(database_name)
    db_connection = TestDatabaseConnection.new(db_name: :postgres)
    db_connection.create_database(database_name) unless db_connection.database_exists?(database_name)
  end

  class TestDatabaseConnection < DatabaseConnection
    def cleanup
      connection.tables.each do |db_table|
        exec("TRUNCATE TABLE #{db_table};")
      end
    end

    def database_exists?(name)
      connection[:pg_database].where(datname: name).count.positive?
    end

    def create_database(name)
      exec("CREATE DATABASE #{name};")
    end

    def table_exists?(table_name)
      connection.tables.include?(table_name.to_sym)
    end
  end
end

RSpec.configure do |config|
  config.include(DatabaseHelpers)

  config.around(opensips: true) do |example|
    setup_database(ENV.fetch("OPENSIPS_DB_NAME"))

    unless opensips_database_connection.table_exists?(:load_balancer)
      opensips_database_connection.exec(
        file_fixture("opensips_load_balancer_create.sql").read
      )
    end

    example.run

    opensips_database_connection.cleanup
  end
end
