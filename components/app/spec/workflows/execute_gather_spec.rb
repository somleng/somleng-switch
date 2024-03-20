require "spec_helper"

RSpec.describe ExecuteGather, type: :call_controller do
  it "creates a TTS event with the correct number of characters" do
    say_content = "Hello World"
    nested_verbs = [
      TwiML::SayVerb.new(name: "Say", content: say_content, attributes: { "voice" => "man", "loop" => "5" }),
      TwiML::PlayVerb.new(name: "Play", content: "http://api.twilio.com/cowbell.mp3", attributes: { "loop" => "3" }),
      TwiML::SayVerb.new(name: "Say", content: say_content, attributes: { "voice" => "woman" })
    ]

    verb = build_verb(nested_verbs:)
    context = build_controller(stub_voice_commands: { ask: build_input_result })
    tts_event_notifier = instance_spy(TTSEventNotifier)

    ExecuteGather.call(verb, **build_workflow_options(context:, tts_event_notifier:))

    expect(tts_event_notifier).to have_received(:notify).with(
      any_args, hash_including(tts_voice: "Basic.Kal", num_chars: say_content.length * 5)
    )
    expect(tts_event_notifier).to have_received(:notify).with(
      any_args, hash_including(tts_voice: "Basic.Slt", num_chars: say_content.length)
    )
  end

  def build_verb(**options)
    TwiML::GatherVerb.new(
      name: "Gather",
      attributes: {},
      nested_verbs: [],
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

  def build_input_result(utterance = nil)
    instance_spy(
      Adhearsion::CallController::Input::Result,
      status: utterance.present? ? :match : :noinput,
      utterance:
    )
  end
end
