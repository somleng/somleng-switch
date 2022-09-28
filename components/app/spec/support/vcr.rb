require "vcr"

VCR.configure do |c|
  c.hook_into :webmock
end

RSpec.configure do |config|
  config.around(vcr: true) do |example|
    original_cassette_library_dir = nil

    VCR.configure do |vcr_config|
      original_cassette_library_dir = vcr_config.cassette_library_dir
      vcr_config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
    end

    cassette = example.metadata[:cassette] || raise(ArgumentError, "You must specify a cassette")
    vcr_options = example.metadata[:vcr_options] || {}
    VCR.use_cassette(cassette, vcr_options) { example.run }

    VCR.configure do |vcr_config|
      vcr_config.cassette_library_dir = original_cassette_library_dir
    end
  end

  config.around(allow_network_requests: true) do |example|
    VCR.turned_off do
      WebMock.allow_net_connect!
      example.run
      WebMock.disable_net_connect!
    end
  end
end
