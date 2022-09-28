require_relative "../spec_helper"

RSpec.describe EncryptedEnvironmentVariables do
  it "Decrypts environment variables from the parameter store" do
    environment = {
      "FOOBAR_SSM_PARAMETER_NAME" => "foobar",
      "BAZ_SSM_PARAMETER_NAME" => "baz"
    }

    ssm_client = Aws::SSM::Client.new(
      stub_responses: {
        get_parameters: {
          parameters: [
            Aws::SSM::Types::Parameter.new(
              name: "baz",
              value: "baz-secret"
            ),
            Aws::SSM::Types::Parameter.new(
              name: "foobar",
              value: "foobar-secret"
            )
          ]
        }
      }
    )

    EncryptedEnvironmentVariables.new(ssm_client:, environment:).decrypt

    expect(environment).to include(
      "FOOBAR" => "foobar-secret",
      "BAZ" => "baz-secret"
    )
  end
end
