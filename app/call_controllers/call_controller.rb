require "somleng/twilio_http_client"
require "somleng/twilio_http_client/client"
require "somleng/twilio_http_client/request"

class CallController < Adhearsion::CallController
  MAX_LOOP = 100
  SLEEP_BETWEEN_REDIRECTS = 1
  DEFAULT_TWILIO_MAX_LENGTH = 3600
  DEFAULT_TWILIO_VOICE = "man".freeze
  DEFAULT_TWILIO_LANGUAGE = "en".freeze

  DIAL_CALL_STATUSES = {
    no_answer: "no-answer",
    answer: "completed",
    timeout: "no-answer",
    error: "failed",
    busy: "busy",
    in_progress: "in-progress",
    ringing: "ringing"
  }.freeze

  before :register_event_handlers

  def run
    @call_properties = build_call_properties

    twiml_document = request_twiml
    execute_twiml(twiml_document)
  end

  private

  attr_reader :call_properties

  def normalized_call
    @normalized_call ||= NormalizedCall.new(call)
  end

  def register_event_handlers
    NotifyCallEvent::EVENT_TYPES.keys.each do |event_type|
      call.register_event_handler(event_type) { |event| NotifyCallEvent.new(event).call }
    end
  end

  def build_call_properties
    return metadata[:call_properties] if metadata[:call_properties].present?

    response = call_platform_client.create_call(to: normalized_call.to)
    CallProperties.new(
      voice_request_url: response.voice_request_url,
      voice_request_method: response.voice_request_method,
      account_sid: response.account_sid,
      auth_token: response.auth_token,
      call_sid: response.call_sid,
      direction: response.direction,
      api_version: response.api_version
    )
  end

  def request_twiml
    http_request = build_twilio_http_request(
      request_url: call_properties.voice_request_url,
      request_method: call_properties.voice_request_method,
      call_status: "ringing"
    )

    response = http_request.execute!
    response.body
  end

  def execute_twiml(response)
    redirection = nil
    with_twiml(response) do |node|
      content = node.content
      options = twilio_options(node)
      case node.name
      when "Reject"
        execute_twiml_verb(:reject, false, options)
        break
      when "Play"
        execute_twiml_verb(:play, true, content, options)
      when "Gather"
        break if (redirection = execute_twiml_verb(:gather, true, node, options))
      when "Redirect"
        redirection = execute_twiml_verb(:redirect, false, content, options)
        break
      when "Hangup"
        break
      when "Say"
        execute_twiml_verb(:say, true, content, options)
      when "Pause"
        not_yet_supported!
      when "Bridge"
        not_yet_supported!
      when "Dial"
        break if (redirection = execute_twiml_verb(:dial, true, node, options))
      else
        raise(ArgumentError, "Invalid element '#{node.name}'")
      end
    end
    redirection ? redirect(*redirection) : hangup
  end

  def build_twilio_http_request(options = {})
    Somleng::TwilioHttpClient::Request.new(
      client: http_client,
      call_from: normalized_call.from,
      call_to: normalized_call.to,
      call_sid: call_properties.call_sid,
      call_direction: call_properties.direction,
      account_sid: call_properties.account_sid,
      api_version: call_properties.api_version,
      auth_token: call_properties.auth_token,
      **options
    )
  end

  def http_client
    @http_client ||= Somleng::TwilioHttpClient::Client.new(
      logger: logger
    )
  end

  def answered?
    return if call.blank?

    normalized_call.answer_time
  end

  def answer!
    answer unless answered?
  end

  def redirect(url = nil, options = {})
    http_request = build_twilio_http_request(
      request_method: options.delete("method") || "post",
      request_url: relative_or_absolute_uri(url),
      call_status: "in-progress",
      body: options
    )

    response = http_request.execute!
    execute_twiml(response.body)
  end

  def relative_or_absolute_uri(uri)
    URI.join(http_client.last_request_url, uri.to_s).to_s
  end

  def execute_twiml_verb(verb, answer_call, *args)
    answer! if answer_call
    send("twilio_#{verb}", *args)
  end

  def twilio_reject(options = {})
    reject(options["reason"] == "busy" ? :busy : :decline)
  end

  def twilio_redirect(url, options = {})
    raise(Adhearsion::Twilio::TwimlError, "invalid redirect url") if url&.empty?

    sleep(SLEEP_BETWEEN_REDIRECTS)
    [url, options]
  end

  def twilio_gather(node, options = {})
    ask_params = []
    ask_options = {}

    node.children.each do |nested_verb_node|
      verb = nested_verb_node.name
      unless %w[Say Play Pause].include?(verb)
        raise(
          Adhearsion::Twilio::TwimlError,
          "Nested verb '<#{verb}>' not allowed within '<#{node.name}>'"
        )
      end

      nested_verb_options = twilio_options(nested_verb_node)
      output_count = twilio_loop(nested_verb_options).count
      output_params = { value: nested_verb_node.content }
      output_params.merge!(options_for_twilio_say(nested_verb_options)) if verb == "Say"
      ask_params << Array.new(output_count, output_params)
    end

    ask_options[:timeout] = options.fetch("timeout", 5).to_i.seconds

    if options["finishOnKey"]
      ask_options[:terminator] = options["finishOnKey"] if options["finishOnKey"] =~ /^(?:\d|\*|\#)$/
    else
      ask_options[:terminator] = "#"
    end

    ask_options[:limit] = options["numDigits"].to_i if options["numDigits"]
    ask_params << nil if ask_params.blank?
    ask_params.flatten!

    logger.info("Executing ask with params: #{ask_params} and options: #{ask_options}")
    result = ask(*ask_params, ask_options)

    digits = result.utterance if %i[match nomatch].include?(result.status)

    return if digits.blank? && options["actionOnEmptyResult"] != "true"

    action_payload = {}
    action_payload["method"] = options["method"]
    action_payload["Digits"] = digits if digits.present?

    [options["action"], action_payload]
  end

  def twilio_say(words, options = {})
    voice_params = options_for_twilio_say(options)
    twilio_loop(options).each do
      doc = RubySpeech::SSML.draw do
        voice(voice_params) do
          string(words)
        end
      end

      say(doc)
    end
  end

  def options_for_twilio_say(options = {})
    {
      name: options.fetch("voice") { DEFAULT_TWILIO_VOICE },
      language: options.fetch("language") { DEFAULT_TWILIO_LANGUAGE }
    }
  end

  def options_for_twilio_dial(options = {})
    global = options.delete(:global)
    global = true unless global == false
    params = {}
    params[:from] = options["callerId"] if options["callerId"]
    params[:ringback] = options["ringToneUrl"] if options["ringToneUrl"]
    params[:for] = (options["timeout"] ? options["timeout"].to_i.seconds : 30.seconds) if global
    params
  end

  def twilio_dial(node, options = {})
    params = options_for_twilio_dial(options)
    to = {}

    node.children.each do |nested_noun_node|
      break if nested_noun_node.text?

      noun = nested_noun_node.name
      unless ["Number"].include?(noun)
        raise(
          Adhearsion::Twilio::TwimlError,
          "Nested noun '<#{noun}>' not allowed within '<#{node.name}>'"
        )
      end

      nested_noun_options = twilio_options(nested_noun_node)
      specific_dial_options = options_for_twilio_dial(nested_noun_options.merge(global: false))

      to[nested_noun_node.content.strip] = specific_dial_options
    end

    to = node.content if to.empty?

    dial_status = dial(to, params)

    dial_call_status_options = {
      "DialCallStatus" => DIAL_CALL_STATUSES[dial_status.result]
    }

    # try to find the joined call
    outbound_call = dial_status.joins.select do |_outbound_leg, join_status|
      join_status.result == :joined
    end.keys.first

    if outbound_call
      dial_call_status_options["DialCallSid"] = outbound_call.id
      dial_call_status_options["DialCallDuration"] = dial_status.joins[outbound_call].duration.to_i
    end

    if options["action"]
      [
        options["action"],
        {
          "method" => options["method"]
        }.merge(dial_call_status_options)
      ]
    end
  end

  def twilio_play(path, options = {})
    twilio_loop(options).each do
      play_audio(path)
    end
  end

  def parse_twiml(xml)
    logger.info("Parsing TwiML: #{xml}")
    begin
      doc = ::Nokogiri::XML(xml) do |config|
        config.options = Nokogiri::XML::ParseOptions::NOBLANKS
      end
    rescue Nokogiri::XML::SyntaxError => e
      raise(Adhearsion::Twilio::TwimlError, "Error while parsing XML: #{e.message}. XML Document: #{xml}")
    end
    raise(Adhearsion::Twilio::TwimlError, "The root element must be the '<Response>' element") if doc.root.name != "Response"

    doc.root.children
  end

  def with_twiml(raw_response)
    doc = parse_twiml(raw_response)
    doc.each do |node|
      yield node
    end
  rescue Adhearsion::Twilio::TwimlError => e
    logger.error(e.message)
  end

  def twilio_loop(twilio_options)
    return MAX_LOOP.times if twilio_options["loop"].to_s == "0"

    [twilio_options.fetch("loop", 1).to_i, MAX_LOOP].min.times
  end

  def twilio_options(node)
    options = {}
    node.attributes.each do |key, attribute|
      options[key] = attribute.value
    end
    options
  end

  def not_yet_supported!
    raise ArgumentError, "Not yet supported"
  end
end
