module Services
  class Client
    attr_reader :lambda_client

    def initialize(**options)
      @lambda_client = options.fetch(:lambda_client) { default_client }
    end

    def build_client_gateway_dial_string(username:, destination:)
      response = invoke_lambda(
        "serviceAction" => "BuildClientGatewayDialString",
        "parameters" => {
          client_identifier: username,
          destination: destination
        }
      )
      response.fetch("dial_string")
    end

    private

    def invoke_lambda(payload)
      response = lambda_client.invoke(
        function_name: Services.configuration.function_arn,
        payload: payload.to_json
      )
      JSON.parse(response.payload.read)
    end

    def default_client
      Aws::Lambda::Client.new(region: Services.configuration.function_region)
    end
  end
end
