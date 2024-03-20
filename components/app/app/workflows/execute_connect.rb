require_relative "execute_twiml_verb"

class ExecuteConnect < ExecuteTwiMLVerb
  def call
    answer!

    url = verb.stream_noun.attributes.fetch("url")
    response = create_audio_stream(url:)

    component = build_component(response.sid)

    logger.info("-----ABOUT TO EXECUTE AUDIO FORK---------")

    context.execute_component_and_await_completion(component) do
      logger.info("--------AUDIO FORK EXECUTED IN BLOCK-----------")
    end

    logger.info("-----AUDIO FORK EXECUTED AND AWAITING FOR RESPONSE IT SHOULD NOT GET HERE----")
  end

  private

  def create_audio_stream(url)
    call_platform_client.create_audio_stream(phone_call_id: call_properties.call_sid, url:)
  end

  def build_component(stream_sid)
    Rayo::Component::TwilioConnect::Stream.new(
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
