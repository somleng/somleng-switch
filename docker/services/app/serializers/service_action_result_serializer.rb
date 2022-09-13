class ServiceActionResultSerializer
  attr_reader :result

  def initialize(result:)
    @result = result
  end

  def as_json
    result.to_json
  end
end
