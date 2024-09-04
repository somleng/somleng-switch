class ApplicationRecord
  class << self
    attr_accessor :table_name

    def exists?(**)
      where(**).count.positive?
    end

    def where(database_connection:, **)
      table(database_connection:).where(**)
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
