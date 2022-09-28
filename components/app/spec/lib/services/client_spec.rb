require "spec_helper"

module Services
  RSpec.describe Client do
    describe "#build_client_gateway_dial_string" do
      it "builds a dial string" do
        lambda_client = Aws::Lambda::Client.new(
          stub_responses: {
            invoke: {
              payload: StringIO.new(
                {
                  "dial_string" => "dial-string"
                }.to_json
              )
            }
          }
        )
        client = Client.new(lambda_client: lambda_client)

        result = client.build_client_gateway_dial_string(
          username: "user1",
          destination: "85516701722"
        )
        expect(result).to eq("dial-string")

        build_client_gateway_dial_string_request = lambda_client.api_requests.first
        expect(build_client_gateway_dial_string_request).to match(
          lambda_request(
            "serviceAction" => "BuildClientGatewayDialString",
            "parameters" => {
              client_identifier: "user1",
              destination: "85516701722"
            }
          )
        )
      end
    end

    def lambda_request(payload)
      hash_including(
        operation_name: :invoke,
        params: hash_including(
          function_name: AppSettings.fetch(:services_function_arn),
          payload: payload.to_json
        )
      )
    end
  end
end
