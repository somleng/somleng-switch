require "spec_helper"

module CallPlatform
  RSpec.describe Client do
    it "updates the switch capacity" do
      client = Client.new(http_client_options: { username: "somleng", password: "secret" })
      stub_request(:post, "https://api.somleng.org/services/switch_capacities")

      client.update_switch_capacity(
        region: "hydrogen",
        capacity: 2
      )

      expect(WebMock).to have_requested(
        :post, "https://api.somleng.org/services/switch_capacities"
      ).with(
        body: { region: "hydrogen", capacity: 2 }.to_json,
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Basic #{Base64.strict_encode64('somleng:secret')}"
        }
      )
    end

    it "handles client errors" do
      client = Client.new
      stub_request(:post, "https://api.somleng.org/services/switch_capacities").to_return(status: 500)

      client.update_switch_capacity(
        region: "hydrogen",
        capacity: 2
      )
    end
  end
end
