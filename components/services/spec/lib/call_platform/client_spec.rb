require "spec_helper"

module CallPlatform
  RSpec.describe Client do
    it "updates the capacity" do
      client = Client.new(http_client_options: { username: "call-service", password: "secret" })
      stub_request(:post, "https://api.somleng.org/services/call_service_capacities")

      client.update_capacity(
        region: "hydrogen",
        capacity: 2
      )

      expect(WebMock).to have_requested(
        :post, "https://api.somleng.org/services/call_service_capacities"
      ).with(
        body: { region: "hydrogen", capacity: 2 }.to_json,
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Basic #{Base64.strict_encode64('call-service:secret')}"
        }
      )
    end

    it "handles client errors" do
      error_handler = class_spy(Sentry)
      client = Client.new(capture_errors: true, error_handler:)
      stub_request(:post, "https://api.somleng.org/services/call_service_capacities").to_return(status: 500)

      client.update_capacity(
        region: "hydrogen",
        capacity: 2
      )

      expect(error_handler).to have_received(:capture_message)
    end
  end
end
