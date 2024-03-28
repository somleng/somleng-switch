require "spec_helper"

RSpec.describe ExecuteSay, type: :call_controller do
  it "creates a TTS event with the correct number of characters" do
    verb = build_verb(content: "Hello World")
    context = build_controller(stub_voice_commands: :say)
    tts_event_notifier = instance_spy(TTSEventNotifier)

    ExecuteSay.call(verb, **build_workflow_options(context:, tts_event_notifier:))

    expect(context).to have_received(:say).exactly(1).times
    expect(tts_event_notifier).to have_received(:notify).with(
      any_args, hash_including(num_chars: verb.content.length)
    )
  end

  it "handles infinite loops" do
    verb = build_verb(content: "Hello World", attributes: { "loop" => "0" })
    context = build_controller(stub_voice_commands: :say)
    tts_event_notifier = instance_spy(TTSEventNotifier)

    ExecuteSay.call(verb, **build_workflow_options(context:, tts_event_notifier:))

    expect(context).to have_received(:say).exactly(1000).times
    expect(tts_event_notifier).to have_received(:notify).with(
      any_args, hash_including(num_chars: verb.content.length * 1000)
    )
  end

  def build_verb(**options)
    TwiML::SayVerb.new(
      name: "Say",
      attributes: {},
      content: "Hello World",
      **options
    )
  end

  def build_workflow_options(**options)
    context = options.fetch(:context) { build_controller }

    {
      context:,
      call_properties: build_call_properties,
      phone_call: context.call,
      call_platform_client: context.call_platform_client,
      tts_event_notifier: instance_spy(TTSEventNotifier),
      **options
    }
  end
end
