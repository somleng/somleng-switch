require "pg"

class DatabaseConnection
  attr_reader :db_name

  def initialize(db_name:)
    @db_name = db_name
  end

  def exec(sql)
    connection.exec(sql)
  end

  def any_records?(sql)
    exec(sql).ntuples.positive?
  end

  def connection
    puts "Connecting to database ..."
    puts pg_connection_options
    @connection ||= PG.connect(pg_connection_options)
  end

  def pg_connection_options
    {
      host: ENV["DB_HOST"],
      port: ENV["DB_PORT"],
      user: ENV["DB_USER"],
      password: ENV["DB_PASSWORD"],
      dbname: db_name
    }.compact
  end
end
