module DatabaseHelpers
  def public_gateway_database_connection
    @public_gateway_database_connection ||= TestDatabaseConnection.new(
      db_name: ENV.fetch("PUBLIC_GATEWAY_DB_NAME")
    )
  end

  def client_gateway_database_connection
    @client_gateway_database_connection ||= TestDatabaseConnection.new(
      db_name: ENV.fetch("CLIENT_GATEWAY_DB_NAME")
    )
  end

  def setup_database(database_name)
    db_connection = TestDatabaseConnection.new(db_name: :postgres)
    db_connection.create_database(database_name) unless db_connection.database_exists?(database_name)
  end

  class TestDatabaseConnection < DatabaseConnection
    def create_tables(tables)
      tables.each do |table_name, create_script|
        next if table_exists?(table_name)

        exec(create_script)
      end
    end

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

  config.around(public_gateway: true) do |example|
    setup_database(ENV.fetch("PUBLIC_GATEWAY_DB_NAME"))

    public_gateway_database_connection.create_tables(
      load_balancer: file_fixture("opensips_load_balancer_create.sql").read,
      address: file_fixture("opensips_permissions_create.sql").read
    )

    example.run

    public_gateway_database_connection.cleanup
  end

  config.around(client_gateway: true) do |example|
    setup_database(ENV.fetch("CLIENT_GATEWAY_DB_NAME"))

    client_gateway_database_connection.create_tables(
      load_balancer: file_fixture("opensips_load_balancer_create.sql").read,
      rtpengine: file_fixture("opensips_rtpengine_create.sql").read,
      domain: file_fixture("opensips_domain_create.sql").read,
      location: file_fixture("opensips_usrloc_create.sql").read
    )

    example.run

    client_gateway_database_connection.cleanup
  end
end
