require_relative "execute_twiml_verb"

class ExecuteConnect < ExecuteTwiMLVerb
  def call
    answer!

    url = verb.stream_noun.attributes.fetch("url")
    response = create_audio_stream(url:)
    component = build_component(stream_sid: response.id, url:)
    context.execute_component_and_await_completion(component)
  end

  private

  def create_audio_stream(url:)
    call_platform_client.create_audio_stream(phone_call_id: call_properties.call_sid, url:)
  end

  def build_component(url:, stream_sid:)
    Rayo::Component::TwilioStream::Start.new(
      uuid: phone_call.id,
      url:,
      metadata: {
        call_sid: call_properties.call_sid,
        account_sid: call_properties.account_sid,
        stream_sid:
      }.to_json
    )
  end
end
