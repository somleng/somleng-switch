if AppSettings.env == "development" || AppSettings.env == "test"
  ENV["AWS_DEFAULT_REGION"] ||= "ap-southeast-1"

  require "resolv"

  FAKE_LAMBDA_RESPONSES = {
    "BuildClientGatewayDialString" => Class.new do
      attr_reader :destination

      def initialize(parameters)
        @destination = parameters.fetch("destination")
      end

      def to_h
        destination_host = ENV.fetch("TESTING_HOST", "10.0.0.1")
        client_gateway_host = ENV.fetch("CLIENT_GATEWAY_HOST", "10.0.0.2")

        {
          destination_address: "#{destination}@#{resolve_address(destination_host)}:5060",
          proxy_address: resolve_address(client_gateway_host)
        }
      end

      private

      def resolve_address(hostname)
        Resolv.getaddress(hostname)
      rescue Resolv::ResolvError
        hostname
      end
    end
  }.freeze

  Aws.config[:lambda] ||= {
    stub_responses: {
      invoke: lambda { |context|
        payload = JSON.parse(context.params.fetch(:payload))
        service_action = payload.fetch("serviceAction")
        parameters = payload.fetch("parameters")
        response = FAKE_LAMBDA_RESPONSES.fetch(service_action).new(parameters).to_h
        { payload: StringIO.new(response.to_json) }
      }
    }
  }

  Aws.config[:polly] ||= {
    stub_responses: {
      describe_voices: {
        voices: [
          { gender: "Female", id: "Joanna", language_code: "en-US", supported_engines: [ "standard" ] },
          { gender: "Female", id: "Lotte", language_code: "nl-NL", supported_engines: [ "neural" ] },
          { gender: "Female", id: "Vitoria", language_code: "pt-BR", supported_engines: %w[neural standard] }
        ]
      }
    }
  }
end
