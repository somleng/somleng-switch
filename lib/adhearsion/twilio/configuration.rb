class Adhearsion::Twilio::Configuration
  DEFAULT_AUTH_TOKEN = "ADHEARSION_TWILIO_AUTH_TOKEN"
  DEFAULT_VOICE_REQUEST_METHOD = "POST"
  DEFAULT_STATUS_CALLBACK_METHOD = "POST"

  def voice_request_url
    config.voice_request_url
  end

  def voice_request_method
    config.voice_request_method.presence || DEFAULT_VOICE_REQUEST_METHOD
  end

  def status_callback_url
    config.status_callback_url
  end

  def status_callback_method
    config.status_callback_method.presence || DEFAULT_STATUS_CALLBACK_METHOD
  end

  def account_sid
    config.account_sid
  end

  def auth_token
    config.auth_token || DEFAULT_AUTH_TOKEN
  end

  def default_female_voice
    config.default_female_voice
  end

  def default_male_voice
    config.default_male_voice
  end

  def rest_api_enabled?
    config.rest_api_enabled.to_i == 1
  end

  def rest_api_phone_calls_url
    config.rest_api_phone_calls_url
  end

  def rest_api_phone_call_events_url
    config.rest_api_phone_call_events_url
  end

  private

  def config
    Adhearsion.config[:twilio]
  end
end
