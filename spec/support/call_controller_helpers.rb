module CallControllerHelpers
  def build_controller(options = {})
    call = options.delete(:call) || build_fake_call
    metadata = options.fetch(:metadata, {})
    metadata.reverse_merge!(
      voice_request_url: "https://example.com/twiml",
      voice_request_method: "POST",
      call_sid: SecureRandom.uuid,
      direction: "outbound-api",
      account_sid: SecureRandom.uuid,
      api_version: "2010-04-01",
      auth_token: SecureRandom.alphanumeric
    )
    controller = CallController.new(call, metadata)
    (%i[hangup answer reject sleep] + Array(options[:stub_voice_commands])).each do |arg|
      arg, return_value = Array(arg).first
      allow(controller).to receive(arg).and_return(return_value)
    end
    controller
  end

  def build_fake_call(options = {})
    variables = options.fetch(:variables) do
      {
        "variable_sip_from_host" => "192.168.1.1",
        "variable_sip_to_host" => "192.168.2.1",
        "variable_sip_network_ip" => "192.168.3.1"
      }
    end

    fake_call = instance_spy(
      Adhearsion::Call,
      from: "Extension 1000 <#{options.fetch(:from) { '1000' }}@192.168.42.234>",
      to: "#{options.fetch(:to) { '85512456869' }}@192.168.42.234",
      id: options.fetch(:id) { SecureRandom.uuid },
      variables: variables
    )

    fake_call
  end

  def stub_twiml_request(controller, response:)
    responses = Array(response).map { |body| { body: body } }
    stub_request(:any, controller.metadata.fetch(:voice_request_url)).to_return(*responses)
  end
end

RSpec.configure do |config|
  config.include(CallControllerHelpers, type: :call_controller)
  config.before(type: :call_controller) do
    Adhearsion::Logging.silence!
  end
end
