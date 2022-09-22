module Services
  class Client
    attr_reader :lambda_client

    def initialize(lambda_client: Aws::Lambda::Client.new)
      @lambda_client = lambda_client
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
  end
end
