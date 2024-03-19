class ResolveTTSVoice < ApplicationWorkflow
  BASIC_TTS_MAPPING = {
    "man" => "Basic.Kal",
    "woman" => "Basic.Slt"
  }.freeze

  attr_reader :default, :voice, :language

  def initialize(default:, **options)
    @default = find(default)
    @voice = options[:voice]
    @language = options[:language]
  end

  def call
    voice_identifier = voice
    voice_identifier = BASIC_TTS_MAPPING.fetch(voice) if BASIC_TTS_MAPPING.key?(voice)
    voice_identifier ||= resolve_tts_voice_by_language&.identifier

    find(voice_identifier) || default
  end

  private

  def find(identifier)
    TTSVoices::Voice.find(identifier)
  end

  def resolve_tts_voice_by_language
    return default if language.blank?
    return default if default.language.casecmp(language).zero?

    find_by_language_and_provider
  end

  def find_by_language_and_provider
    TTSVoices::Voice.all.find do |tts_voice|
      tts_voice.provider == default.provider && tts_voice.language.casecmp(language).zero?
    end
  end
end
