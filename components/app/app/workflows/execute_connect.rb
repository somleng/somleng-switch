require_relative "execute_twiml_verb"

class ExecuteConnect < ExecuteTwiMLVerb
  def call
    answer!

    url = verb.stream_noun.url
    custom_parameters = verb.stream_noun.parameters
    response = create_audio_stream(url:, custom_parameters:)
    component = build_component(stream_sid: response.id, url:, custom_parameters:)
    context.execute_component_and_await_completion(component)
  end

  private

  def create_audio_stream(**params)
    call_platform_client.create_audio_stream(phone_call_id: call_properties.call_sid, **params)
  end

  def build_component(url:, stream_sid:, custom_parameters:)
    Rayo::Component::TwilioStream::Start.new(
      uuid: phone_call.id,
      url:,
      metadata: Base64.urlsafe_encode64({
        call_sid: call_properties.call_sid,
        account_sid: call_properties.account_sid,
        stream_sid:,
        custom_parameters:
      }.to_json)
    )
  end
end
