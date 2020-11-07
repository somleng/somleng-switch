require_relative "configuration"
require_relative "call"
require_relative "twiml_error"
require_relative "rest_api/phone_call"
require_relative "rest_api/phone_call_event"
require_relative "event/recording_started"

require "somleng/twilio_http_client/client"
require "somleng/twilio_http_client/request"

module Adhearsion::Twilio::ControllerMethods
  extend ActiveSupport::Concern

  MAX_LOOP = 100
  SLEEP_BETWEEN_REDIRECTS = 1
  DEFAULT_TWILIO_RECORD_TIMEOUT = 5
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

  included do
    before :register_event_handlers
  end

  private

  def register_event_handlers
    call.register_event_handler(Adhearsion::Event::Ringing) { |event| handle_phone_call_event(event: event) }
    call.register_event_handler(Adhearsion::Event::Answered) { |event| handle_phone_call_event(event: event) }
    call.register_event_handler(Adhearsion::Event::End) { |event| handle_phone_call_event(event: event) }
    call.register_event_handler(Adhearsion::Event::Complete) { |event| handle_phone_call_event(event: event) }
  end

  def handle_phone_call_event(options = {})
    build_rest_api_phone_call_event(options).notify!
  end

  def build_rest_api_phone_call_event(options = {})
    Adhearsion::Twilio::RestApi::PhoneCallEvent.new({ logger: logger }.merge(options))
  end

  def answered?
    call&.answer_time
  end

  def answer!
    answer unless answered?
  end

  def notify_voice_request_url
    http_request = build_twilio_http_request(
      request_url: voice_request_url,
      request_method: voice_request_method,
      call_status: "ringing"
    )

    response = http_request.execute!
    execute_twiml(response.body)
  end

  def http_client
    @http_client ||= Somleng::TwilioHttpClient::Client.new(
      logger: logger
    )
  end

  def default_twilio_http_request_options
    {
      client: http_client,
      call_from: twilio_call.from,
      call_to: twilio_call.to,
      call_sid: call_sid,
      call_direction: call_direction,
      account_sid: account_sid,
      api_version: api_version,
      auth_token: auth_token
    }
  end

  def build_twilio_http_request(options = {})
    Somleng::TwilioHttpClient::Request.new(default_twilio_http_request_options.merge(options))
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
      when "Record"
        break if (redirection = execute_twiml_verb(:record, true, options))
      else
        raise(ArgumentError, "Invalid element '#{node.name}'")
      end
    end
    redirection ? redirect(*redirection) : hangup
  end

  def execute_twiml_verb(verb, answer_call, *args)
    answer! if answer_call
    send("twilio_#{verb}", *args)
  end

  def twilio_record(twilio_options = {})
    phone_call_event = Adhearsion::Twilio::Event::RecordingStarted.new(
      twilio_call.id, twilio_options_for_record_event(twilio_options)
    )
    rest_api_phone_call_event = build_rest_api_phone_call_event(event: phone_call_event)
    rest_api_phone_call_event.notify!
    notify_response = rest_api_phone_call_event.notify_response
    action_recording_url = notify_response["recording_url"]

    record_component = record(options_for_twilio_record(twilio_options))
    recording = record_component.recording
    recording_duration = recording.duration
    action_recording_url ||= recording.uri

    unless recording_duration.zero?
      [
        twilio_options["action"],
        {
          "RecordingUrl" => action_recording_url,
          "RecordingDuration" => (recording_duration / 1000),
          "method" => twilio_options["method"]
        }
      ]
    end
  end

  def twilio_options_for_record_event(twilio_options = {})
    parsed_options = twilio_options.dup

    if recording_status_callback = parsed_options["recordingStatusCallback"]
      url = relative_or_absolute_uri(recording_status_callback)
      parsed_options["recordingStatusCallback"] = url
    end

    parsed_options
  end

  def options_for_twilio_record(twilio_options = {})
    twilio_play_beep = twilio_options["playBeep"]
    twilio_timeout = twilio_options["timeout"]
    twilio_max_length = twilio_options["maxLength"]

    {
      start_beep: twilio_play_beep != "false",
      final_timeout: (twilio_timeout&.to_i) || DEFAULT_TWILIO_RECORD_TIMEOUT,
      interruptible: true,
      max_duration: (twilio_max_length.to_i > 0 ? twilio_max_length.to_i : DEFAULT_TWILIO_MAX_LENGTH)
    }
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
      output_count = twilio_loop(nested_verb_options, finite: true).count
      ask_options.merge!(send("options_for_twilio_#{verb.downcase}", nested_verb_options))
      ask_params << Array.new(output_count, nested_verb_node.content)
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
    params[:ringback] = options["ringback"] if options["ringback"]
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

  def twilio_call
    @twilio_call ||= setup_twilio_call
  end

  def setup_twilio_call
    logger.info("Setting up Adhearsion::Twilio::Call with call variables: #{call.variables}")
    Adhearsion::Twilio::Call.new(call)
  end

  def configuration
    @configuration ||= Adhearsion::Twilio::Configuration.new
  end

  def rest_api_phone_call
    @rest_api_phone_call ||= Adhearsion::Twilio::RestApi::PhoneCall.new(
      twilio_call: twilio_call, logger: logger
    )
  end

  def voice_request_url
    resolve_configuration(:voice_request_url)
  end

  def voice_request_method
    resolve_configuration(:voice_request_method)
  end

  def call_direction
    resolve_configuration(:direction, false)
  end

  def api_version
    resolve_configuration(:api_version, false)
  end

  def account_sid
    resolve_configuration(:account_sid)
  end

  def auth_token
    resolve_configuration(:auth_token)
  end

  def call_sid
    resolve_configuration(:call_sid, false) || twilio_call.id
  end

  def twilio_request_to
    resolve_configuration(:twilio_request_to, false)
  end

  def resolve_configuration(name, has_global_configuration = true)
    (metadata[name] || (configuration.rest_api_enabled? && metadata[:rest_api_enabled] != false && rest_api_phone_call.public_send(name)) || has_global_configuration && configuration.public_send(name)).presence
  end

  def not_yet_supported!
    raise ArgumentError, "Not yet supported"
  end
end
