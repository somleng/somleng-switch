require "spec_helper"

module SomlengAdhearsion
  module Web
    RSpec.describe API, :web_application do
      let(:app) { API.new }

      it "requires basic authentication" do
        basic_authorize "username", "wrong-password"

        post "/calls"

        expect(last_response.status).to eq(401)
      end

      describe "POST /calls" do
        it "initiates an outbound call" do
          outbound_call = instance_double(Adhearsion::OutboundCall, id: "123456")
          allow(Adhearsion::OutboundCall).to receive(:originate).and_return(outbound_call)

          basic_authorize "adhearsion", "password"
          post(
            "/calls",
            {
              "to" => "+85516701721",
              "from" => "2442",
              "voice_url" => "https://rapidpro.ngrok.com/handle/33/",
              "voice_method" => "GET",
              "status_callback_url" => "https://rapidpro.ngrok.com/handle/33/",
              "status_callback_method" => "POST",
              "sid" => "sample-call-sid",
              "account_sid" => "sample-account-sid",
              "account_auth_token" => "sample-auth-token",
              "direction" => "outbound-api",
              "api_version" => "2010-04-01",
              "default_tts_voice" => "Basic.Kal",
              "routing_parameters" => {
                "destination" => "85516701721",
                "dial_string_prefix" => nil,
                "plus_prefix" => false,
                "national_dialing" => false,
                "host" => "27.109.112.141",
                "username" => nil,
                "symmetric_latching" => true
              }
            }.to_json,
            {
              "CONTENT_TYPE" => "application/json"
            }
          )

          expect(last_response.status).to eq(200)
          expect(json_response["id"]).to eq("123456")
        end
      end

      describe "DELETE /calls/:id" do
        it "ends a call" do
          call = Adhearsion::Call.new
          allow(call).to receive(:id).and_return("123456")
          allow(call).to receive(:hangup)
          Adhearsion.active_calls << call

          basic_authorize "adhearsion", "password"

          delete(
            "/calls/123456",
            {
              "CONTENT_TYPE" => "application/json"
            }
          )

          expect(last_response.status).to eq(204)
          expect(call).to have_received(:hangup)
        end
      end
    end
  end
end
