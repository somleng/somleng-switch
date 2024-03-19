class ExecuteGather < ExecuteTwiMLVerb
  def call
    raise(Errors::TwiMLError, verb.errors.full_messages.to_sentence) unless verb.valid?

    answer!

    digits = ask.utterance
    return if digits.blank? && !verb.action_on_empty_result?

    redirect(build_callback_params(digits))
  end

  private

  def redirect(params)
    throw(:redirect, [verb.action, verb.method, params])
  end

  def build_callback_params(digits)
    return {} if digits.blank?

    {
      "Digits" => digits
    }
  end

  def ask
    context.ask(*build_ask_params, build_ask_options)
  end

  def build_ask_params
    verb.nested_verbs.each_with_object([]) do |nested_verb, result|
      result.concat(Array.new(nested_verb.loop.times.count, build_output_for(nested_verb)))
    end
  end

  def build_ask_options
    ask_options = {}
    ask_options[:timeout] = verb.timeout
    ask_options[:limit] = verb.num_digits if verb.num_digits.present?
    ask_options[:terminator] = verb.finish_on_key if verb.finish_on_key.present?
    ask_options
  end

  def build_output_for(nested_verb)
    case nested_verb.name
    when "Say"
      tts_voice = resolve_tts_voice(nested_verb)
      SSMLDocument.new(content: nested_verb.content, tts_voice:).to_ssml
    when "Play"
      nested_verb.content
    end
  end

  def resolve_tts_voice(verb)
    ResolveTTSVoice.call(
      default: call_properties.default_tts_voice,
      voice: verb.voice,
      language: verb.language
    )
  end
end
