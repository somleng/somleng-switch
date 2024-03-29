class ExecuteSay < ExecuteTwiMLVerb
  attr_reader :tts_event_notifier

  def initialize(verb, **options)
    super
    @tts_event_notifier = options.fetch(:tts_event_notifier) { TTSEventNotifier.new }
  end

  def call
    answer!
    notify_tts_event

    verb.loop.times.each do
      context.say(SSMLDocument.new(content: verb.content, tts_voice:).to_ssml)
    end
  end

  private

  def tts_voice
    @tts_voice ||= ResolveTTSVoice.call(
      default: call_properties.default_tts_voice,
      voice: verb.voice,
      language: verb.language
    )
  end

  def notify_tts_event
    tts_event_notifier.notify(
      call_platform_client,
      phone_call: call_properties.call_sid,
      tts_voice: tts_voice.identifier,
      num_chars: verb.content.length * verb.loop.times.size
    )
  end
end
