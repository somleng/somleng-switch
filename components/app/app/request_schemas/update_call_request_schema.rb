class UpdateCallRequestSchema
  attr_reader :params

  def initialize(params)
    @params = params.with_indifferent_access
  end

  def output
    params.slice(:voice_url, :voice_method, :twiml).symbolize_keys
  end
end
