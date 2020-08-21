require_relative "../../app/web/application"

module RequestHelpers
  def json_response
    JSON.parse(last_response.body)
  end
end

RSpec.configure do |config|
  config.before(web: true) do
    config.include Rack::Test::Methods
    config.include RequestHelpers
  end
end

