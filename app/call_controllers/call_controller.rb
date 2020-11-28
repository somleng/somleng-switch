require "somleng/twilio_http_client"
require "somleng/twilio_http_client/client"
require "somleng/twilio_http_client/request"

class CallController < Adhearsion::CallController
  MAX_LOOP = 100
  SLEEP_BETWEEN_REDIRECTS = 1
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
    self.call_properties = build_call_properties

    endpoint = TwiMLEndpoint.new(
      url: call_properties.voice_request_url,
      http_method: call_properties.voice_request_method,
      auth_token: call_properties.auth_token
    )
    @last_response = endpoint.request(
      "From" => normalized_call.from,
      "To" => normalized_call.to,
      "CallSid" => call_properties.call_sid,
      "CallStatus" => "ringing",
      "Direction" => call_properties.direction,
      "AccountSid" => call_properties.account_sid,
      "ApiVersion" => call_properties.api_version
    )

    execute_twiml(@last_response.body)
  end

  private

  attr_accessor :call_properties

  def normalized_call
    @normalized_call ||= NormalizedCall.new(call)
  end

  def register_event_handlers
    NotifyCallEvent.subscribe_events(call)
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

  def execute_twiml(document)
    logger.info("Parsing TwiML: #{document}")

    twiml = TwiMLParser.new(document).parse

    redirect_args = catch(:redirect) do
      twiml.each do |node|
        content = node.content
        options = twilio_options(node)

        answer if !answered? && %w[Play Gather Redirect Say Dial].include?(node.name)

        case node.name
        when "Reject"
          reject(options["reason"] == "busy" ? :busy : :decline)

          break
        when "Play"
          twilio_loop(options).each do
            play_audio(content)
          end
        when "Gather"
          twilio_gather(node, options)
        when "Redirect"
          raise Errors::TwiMLError, "Redirect must contain a URL" if content.blank?

          sleep(SLEEP_BETWEEN_REDIRECTS)
          throw(:redirect, [content, options])
        when "Hangup"
          hangup
          break
        when "Say"
          voice_params = options_for_twilio_say(options)
          twilio_loop(options).each do
            doc = RubySpeech::SSML.draw do
              voice(voice_params) do
                string(content)
              end
            end

            say(doc)
          end
        when "Dial"
          twilio_dial(node, options)
        else
          raise Errors::TwiMLError, "Invalid element '#{node.name}'"
        end
      end

      false
    end

    redirect(*redirect_args) if redirect_args.present?
  rescue Errors::TwiMLError => e
    logger.error(e.message)
  end

  def answered?
    return if call.blank?

    normalized_call.answer_time
  end

  def redirect(url = nil, options = {})
    endpoint = TwiMLEndpoint.new(
      url: URI.join(@last_response.env.url, url.to_s).to_s,
      http_method: options.delete("method"),
      auth_token: call_properties.auth_token
    )

    request_params = {
      "From" => normalized_call.from,
      "To" => normalized_call.to,
      "CallSid" => call_properties.call_sid,
      "CallStatus" => "in-progress",
      "Direction" => call_properties.direction,
      "AccountSid" => call_properties.account_sid,
      "ApiVersion" => call_properties.api_version
    }.merge(options)

    @last_response = endpoint.request(request_params)

    execute_twiml(@last_response.body)
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

    throw(:redirect, [options["action"], action_payload])
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

    return if options["action"].blank?

    throw(
      :redirect,
      [
        options["action"],
        {
          "method" => options["method"]
        }.merge(dial_call_status_options)
      ]
    )
  end

  def twilio_loop(twilio_options)
    return MAX_LOOP.times if twilio_options["loop"].to_s == "0"

    [twilio_options.fetch("loop", 1).to_i, MAX_LOOP].min.times
  end

  def twilio_options(node)
    node.attributes.each_with_object({}) do |(key, attribute), options|
      options[key] = attribute.value
    end
  end
end
