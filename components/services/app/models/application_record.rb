class ApplicationRecord
  class << self
    attr_accessor :table_name

    def exists?(database_connection:, **query)
      where(database_connection:, **query).count.positive?
    end

    def where(database_connection:, **query)
      table(database_connection:).where(query)
    end

    private

    def table(database_connection:)
      database_connection.table(table_name)
    end
  end

  attr_reader :attributes, :database_connection

  def initialize(database_connection:, **attributes)
    @database_connection = database_connection
    @attributes = attributes
  end

  def save!
    table.insert(attributes)
  end

  private

  def table
    database_connection.table(self.class.table_name)
  end
end
