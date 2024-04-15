require "spec_helper"

module CallPlatform
  RSpec.describe Client do
    describe "#create_media_stream" do
      it "creates a media stream" do
        stub_request(
          :post,
          "https://api.internal.somleng.org/services/media_streams"
        ).to_return(body: { "sid" => "393a227f-0602-4024-b38a-dcbbeed4d5a0" }.to_json)
        client = Client.new(http_client_options: { url: "https://api.internal.somleng.org" })

        response = client.create_media_stream(
          url: "wss://example.com/audio",
          phone_call_id: "phone-call-id",
          custom_parameters: {
            foo: "bar"
          }
        )

        expect(response.id).to eq("393a227f-0602-4024-b38a-dcbbeed4d5a0")
        expect(WebMock).to(have_requested(:post, "https://api.internal.somleng.org/services/media_streams").with { |request|
          request_body = JSON.parse(request.body)
          expect(request_body).to eq(
            "url" => "wss://example.com/audio",
            "phone_call_id" => "phone-call-id",
            "custom_parameters" => { "foo" => "bar" }
          )
        })
      end
    end
  end
end
