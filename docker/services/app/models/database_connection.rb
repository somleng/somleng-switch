require "sequel"

class DatabaseConnection
  attr_reader :db_name

  def initialize(db_name:)
    @db_name = db_name
  end

  def exec(sql)
    connection.run(sql)
  end

  def table(table_name)
    connection[table_name]
  end

  def transaction(&block)
    connection.transaction(&block)
  end

  def connection
    @connection ||= Sequel.connect(database_url)
  end

  private

  def database_url
    ENV.fetch("DATABASE_URL") { build_database_url }
  end

  def build_database_url(options = {})
    user = options.fetch(:user) { ENV.fetch("DB_USER", "postgres") }
    password = options.fetch(:password) { ENV["DB_PASSWORD"] }
    host = options.fetch(:host) { ENV.fetch("DB_HOST", "localhost") }
    port = options.fetch(:port) { ENV.fetch("DB_PORT", 5432) }

    "postgres://#{user}:#{password}@#{host}:#{port}/#{db_name}"
  end
end
