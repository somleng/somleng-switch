TTSVoices.configure do |config|
  if AppSettings.env == "development" || AppSettings.env == "test"
    # Polly provider supports stub_responses
    config.voices = ["Basic", "Polly"]
  end
end
