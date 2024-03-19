require "spec_helper"

RSpec.describe ExecuteTwiML, type: :call_controller do
  it "executes a TwiML document" do
    twiml = <<~TWIML
      <?xml version="1.0" encoding="UTF-8" ?>
      <Response>
        <Play>http://api.twilio.com/cowbell.mp3</Play>
      </Response>
    TWIML
    context = build_controller(stub_voice_commands: :play_audio)

    ExecuteTwiML.call(**build_workflow_options(context:, twiml:))

    expect(context).to have_received(:play_audio).with("http://api.twilio.com/cowbell.mp3")
  end

  it "handles invalid TwiML Verbs" do
    twiml = <<~TWIML
      <?xml version="1.0" encoding="UTF-8" ?>
      <Response>
        <Foobar>http://api.twilio.com/cowbell.mp3</Foobar>
      </Response>
    TWIML
    logger = instance_spy(Logger)

    ExecuteTwiML.call(**build_workflow_options(logger:, twiml:))

    expect(logger).to have_received(:error).with("Invalid element <Foobar>")
  end

  def build_workflow_options(**options)
    context = options.fetch(:context) { build_controller }

    {
      context:,
      call_properties: build_call_properties,
      phone_call: context.call,
      call_platform_client: context.call_platform_client,
      logger: instance_spy(Logger),
      **options
    }
  end
end
