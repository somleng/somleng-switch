class ExecuteRecord < ExecuteTwiMLVerb
  URL_PATTERN = URI::DEFAULT_PARSER.make_regexp(%w[http https]).freeze

  def call
    answer!
    response = create_recording
    record_result = record
    response = update_recording(response.id, record_result)
    redirect(build_callback_params(response, record_result))
  end

  private

  def create_recording
    call_platform_client.create_recording(
      {
        phone_call_id: call_properties.call_sid,
        status_callback_url: verb.status_callback_url,
        status_callback_method: verb.status_callback_method
      }.compact
    )
  end

  def update_recording(id, result)
    call_platform_client.update_recording(
      id,
      raw_recording_url: normalize_recording_url(result.recording.uri),
      external_id: result.component_id
    )
  end

  def record
    context.record(
      max_duration: verb.max_length,
      final_timeout: verb.timeout,
      start_beep: verb.play_beep,
      interruptible: verb.finish_on_key
    )
  end

  def normalize_recording_url(raw_recording_url)
    URL_PATTERN.match(raw_recording_url)[0]
  end

  def redirect(params)
    throw(:redirect, [verb.action, verb.method, params])
  end

  def build_callback_params(response, record_result)
    {
      "RecordingUrl" => response.url,
      "RecordingDuration" => record_result.recording.duration.to_i / 1000
    }
  end
end
