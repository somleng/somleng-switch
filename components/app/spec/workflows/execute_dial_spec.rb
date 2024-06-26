require "spec_helper"

RSpec.describe ExecuteDial, type: :call_controller do
  it "creates a call" do
    verb = build_verb(
      nested_nouns: build_nested_nouns("85516701721", "855715100860", "sip:example.com:5080")
    )
    joined_outbound_call = build_outbound_call(id: "481f77b9-a95b-4c6a-bbb1-23afcc42c959")
    no_answer_outbound_call = build_outbound_call

    context = build_controller(
      stub_voice_commands: {
        dial: build_dial_status(
          :answer,
          joins: {
            joined_outbound_call => build_dial_join_status(:joined, duration: 25),
            no_answer_outbound_call => build_dial_join_status(:no_answer)
          }
        )
      }
    )

    ExecuteDial.call(verb, **build_workflow_options(context:))
  end

  def build_verb(**options)
    TwiML::DialVerb.new(
      name: "Dial",
      attributes: {},
      nested_nouns: [],
      **options
    )
  end

  def build_nested_nouns(*destinations)
    Array(destinations).map do |destination|
      TwiML::TwiMLNode.new(name: destination.start_with?("sip:") ? "Sip" : "Number", content: destination)
    end
  end

  def build_workflow_options(**options)
    context = options.fetch(:context) { build_controller }

    {
      context:,
      call_properties: build_call_properties,
      phone_call: context.call,
      call_platform_client: context.call_platform_client,
      **options
    }
  end

  def build_outbound_call(options = {})
    instance_double(Adhearsion::OutboundCall, options)
  end

  def build_dial_status(result = :answer, joins: {})
    instance_double(Adhearsion::CallController::DialStatus, result:, joins:)
  end

  def build_dial_join_status(result = :joined, options = {})
    instance_double(Adhearsion::CallController::Dial::JoinStatus, result:, **options)
  end
end
