require "spec_helper"

module SomlengAdhearsion
  module Web
    RSpec.describe API, :web_application do
      let(:app) { API.new }

      it "requires basic authentication" do
        basic_authorize "username", "wrong-password"

        post("/calls")

        expect(last_response.status).to eq(401)
      end

      describe "POST /calls" do
        it "initiates an outbound call" do
          call_id = SecureRandom.uuid
          outbound_call = instance_double(Adhearsion::OutboundCall, id: call_id)
          allow(Adhearsion::OutboundCall).to receive(:originate).and_return(outbound_call)

          basic_authorize "adhearsion", "password"
          post(
            "/calls",
            JSON.generate(
              "to" => "+85516701721",
              "from" => "2442",
              "voice_url" => "https://rapidpro.ngrok.com/handle/33/",
              "voice_method" => "GET",
              "status_callback_url" => "https://rapidpro.ngrok.com/handle/33/",
              "status_callback_method" => "POST",
              "sid" => "sample-call-sid",
              "account_sid" => "sample-account-sid",
              "carrier_sid" => "sample-carrier-sid",
              "call_direction" => "outbound",
              "account_auth_token" => "sample-auth-token",
              "direction" => "outbound-api",
              "api_version" => "2010-04-01",
              "default_tts_voice" => "Basic.Kal",
              "routing_parameters" => {
                "address" => nil,
                "destination" => "85516701721",
                "dial_string_prefix" => nil,
                "plus_prefix" => false,
                "national_dialing" => false,
                "host" => "27.109.112.141",
                "username" => nil,
                "sip_profile" => "nat_gateway"
              },
              "billing_parameters" => {
                "enabled" => true,
                "billing_mode" => "prepaid",
                "category" => "outbound_calls"
              }
            ),
            {
              "CONTENT_TYPE" => "application/json"
            }
          )

          expect(last_response.status).to eq(200)
          expect(json_response["id"]).to eq(call_id)
          expect(IPAddr.new(json_response["host"])).to have_attributes(
            private?: true
          )
        end

        context "when the request is invalid" do
          around do |example|
            original_raise_errors = Application.raise_errors
            original_dump_errors = Application.dump_errors
            Application.set :raise_errors, false
            Application.set :dump_errors, false
            example.run
            Application.set :raise_errors, original_raise_errors
            Application.set :dump_errors, original_dump_errors
          end

          it "returns a 500 error" do
            basic_authorize "adhearsion", "password"
            post(
              "/calls",
              "invalid-json",
            )

            expect(last_response.status).to eq(500)
            expect(last_response.body).to eq("Internal Server Error")
          end
        end
      end

      describe "DELETE /calls/:id" do
        it "ends a call" do
          call = Adhearsion::Call.new
          call_id = SecureRandom.uuid
          allow(call).to receive(:id).and_return(call_id)
          allow(call).to receive(:hangup)
          Adhearsion.active_calls << call

          basic_authorize "adhearsion", "password"

          delete(
            "/calls/#{call_id}",
            {
              "CONTENT_TYPE" => "application/json"
            }
          )

          expect(last_response.status).to eq(204)
          expect(call).to have_received(:hangup)
        end
      end

      describe "PATCH /calls/:id" do
        it "Redirect an in progress call to a new URL" do
          basic_authorize "adhearsion", "password"

          patch(
            "/calls/#{SecureRandom.uuid}",
            JSON.generate(
              voice_url: "https://demo.twilio.com/docs/voice.xml",
              voice_method: "GET"
            ),
            {
              "CONTENT_TYPE" => "application/json"
            }
          )

          expect(last_response.status).to eq(204)
        end

        it "Execute new TwiML for an in-progress call" do
          basic_authorize "adhearsion", "password"

          patch(
            "/calls/#{SecureRandom.uuid}",
            JSON.generate(
              twiml: "<Response><Say>Hello World.</Say></Response>"
            ),
            {
              "CONTENT_TYPE" => "application/json"
            }
          )

          expect(last_response.status).to eq(204)
        end
      end
    end
  end
end
