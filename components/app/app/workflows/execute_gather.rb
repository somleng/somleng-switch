class ExecuteGather < ExecuteTwiMLVerb
  AskParameter = Struct.new(:repeat, :content, :tts_voice, :content_length) do
    def to_param
      Array.new(repeat, content)
    end

    def num_tts_chars
      content_length.to_i * repeat.to_i
    end
  end

  attr_reader :tts_event_notifier

  def initialize(verb, **options)
    super
    @tts_event_notifier = options.fetch(:tts_event_notifier) { TTSEventNotifier.new }
  end

  def call
    answer!
    notify_tts_events

    digits = ask.utterance
    return if digits.blank? && !verb.action_on_empty_result?

    redirect(build_callback_params(digits))
  end

  private

  def redirect(params)
    throw(:redirect, [ verb.action, verb.method, params ])
  end

  def build_callback_params(digits)
    return {} if digits.blank?

    {
      "Digits" => digits
    }
  end

  def ask
    context.ask(*ask_parameters.map(&:to_param).flatten, ask_options)
  end

  def ask_parameters
    @ask_parameters ||= verb.nested_verbs.map do |nested_verb|
      build_ask_parameter(nested_verb)
    end
  end

  def build_ask_parameter(nested_verb)
    parameter = case nested_verb.name
    when "Say"
                  build_say_parameter(nested_verb)
    when "Play"
                  build_play_parameter(nested_verb)
    end

    parameter.repeat = nested_verb.loop.times.count
    parameter
  end

  def build_say_parameter(nested_verb)
    tts_voice = resolve_tts_voice(nested_verb)

    AskParameter.new(
      tts_voice:,
      content: SSMLDocument.new(content: nested_verb.content, tts_voice:).to_ssml,
      content_length: nested_verb.content.length
    )
  end

  def build_play_parameter(nested_verb)
    AskParameter.new(content: nested_verb.content)
  end

  def ask_options
    @ask_options ||= begin
      ask_options = {}
      ask_options[:timeout] = verb.timeout
      ask_options[:limit] = verb.num_digits if verb.num_digits.present?
      ask_options[:terminator] = verb.finish_on_key if verb.finish_on_key.present?
      ask_options
    end
  end

  def resolve_tts_voice(verb)
    ResolveTTSVoice.call(
      default: call_properties.default_tts_voice,
      voice: verb.voice,
      language: verb.language
    )
  end

  def notify_tts_events
    ask_parameters.select { |a| a.tts_voice.present? }.each do |parameter|
      tts_event_notifier.notify(
        call_platform_client,
        phone_call: call_properties.call_sid,
        tts_voice: parameter.tts_voice.identifier,
        num_chars: parameter.num_tts_chars
      )
    end
  end
end
