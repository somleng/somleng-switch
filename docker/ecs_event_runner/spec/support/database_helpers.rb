module DatabaseHelpers
  def opensips_database_connection
    @opensips_database_connection ||= TestDatabaseConnection.new(
      db_name: ENV.fetch("OPENSIPS_DB_NAME")
    )
  end

  def setup_database(database_name)
    db_connection = TestDatabaseConnection.new(db_name: "postgres")
    db_connection.create_database(database_name) unless db_connection.database_exists?(database_name)
  end

  class TestDatabaseConnection < DatabaseConnection
    def cleanup
      tables.each do |db_table|
        connection.exec("TRUNCATE TABLE #{db_table};")
      end
    end

    def database_exists?(name)
      connection.exec(
        "SELECT 1 FROM pg_database WHERE datname='#{name}';"
      ).ntuples.positive?
    end

    def create_database(name)
      connection.exec("CREATE DATABASE #{name};")
    end

    def table_exists?(table_name)
      tables.include?(table_name)
    end

    def tables
      connection.exec(
        "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';"
      ) do |result|
        result.each_with_object([]) do |row, tables|
          tables << row.fetch("table_name")
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include(DatabaseHelpers)

  config.around(opensips: true) do |example|
    setup_database(ENV.fetch("OPENSIPS_DB_NAME"))

    unless opensips_database_connection.table_exists?("load_balancer")
      opensips_database_connection.exec(
        file_fixture("opensips_load_balancer_create.sql").read
      )
    end

    example.run

    opensips_database_connection.cleanup
  end
end
