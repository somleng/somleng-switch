require "openssl"
require 'digest/sha2'
require 'base64'
require 'cgi'
require "adhearsion/twilio/util/sip_header"

class DrbEndpoint
  # Do not use instance variables in this class!
  # If an instance variable is set,
  # the next time this DrbEndpoint is invoked it will use the previous instance variable
  # DRb is not thread safe!

  DEFAULT_DIAL_STRING_FORMAT = "%{destination}"

  def initiate_outbound_call!(call_json)
    logger.info("Receiving DRb request: #{call_json}")
    call_params = JSON.parse(call_json)
    call_variables = get_call_variables(call_params)

    call_args = [
      call_variables[:dial_string],
      {
        :from => call_variables[:caller_id],
        :controller => CallController,
        :controller_metadata => controller_metadata(call_variables),
        :headers => construct_adhearsion_twilio_headers(call_variables)
      }
    ]

    if call_variables[:disable_originate].to_i != 1
      logger.info("Initiating outbound call with: #{call_args}")
      outbound_call = Adhearsion::OutboundCall.originate(*call_args)
      register_event_end(outbound_call)
      outbound_call.id
    end
  end

  private

  def register_event_end(outbound_call)
    outbound_call.register_event_handler(Adhearsion::Event::End) do |event|
      handle_event_end(event)
    end
  end

  def handle_event_end(event)
    event_details = parse_event(event)
    logger.info("handle_event_end - event details: #{event_details}")
    notify_status_callback_url(event_details) if !answered?(event_details)
  end

  def answered?(event_details)
    get_adhearsion_twilio_call_status(event_details) == :answer || event_details[:answer_epoch].to_i > 0
  end

  def get_adhearsion_twilio_call_status(event_details)
    case event_details[:sip_term_status]
    when "200"
      :answer
    when "486"
      :busy
    when "480", "487", "603"
      :no_answer
    else
      :error
    end
  end

  def construct_adhearsion_twilio_headers(call_variables)
    sip_header_util = Adhearsion::Twilio::Util::SipHeader.new
    headers = {}

    add_adhearsion_twilio_header!(
      sip_header_util,
      headers,
      "Status-Callback-Url",
      call_variables[:status_callback_url]
    )

    add_adhearsion_twilio_header!(
      sip_header_util,
      headers,
      "Status-Callback-Method",
      call_variables[:status_callback_method]
    )

    add_adhearsion_twilio_header!(
      sip_header_util,
      headers,
      "Call-Sid",
      call_variables[:call_sid]
    )

    add_adhearsion_twilio_header!(
      sip_header_util,
      headers,
      "To",
      call_variables[:adhearsion_twilio_to]
    )

    add_adhearsion_twilio_header!(
      sip_header_util,
      headers,
      "From",
      call_variables[:adhearsion_twilio_from]
    )

    add_adhearsion_twilio_header!(
      sip_header_util,
      headers,
      "Direction",
      call_variables[:call_direction]
    )

    add_adhearsion_twilio_header!(
      sip_header_util,
      headers,
      "Account-Sid",
      call_variables[:account_sid]
    )

    add_adhearsion_twilio_header!(
      sip_header_util,
      headers,
      "Encrypted-Auth-Token",
      call_variables[:encrypted_auth_token]
    )

    add_adhearsion_twilio_header!(
      sip_header_util,
      headers,
      "Encrypted-Auth-Token-IV",
      call_variables[:encrypted_auth_token_iv]
    )

    if !call_variables[:encrypted_auth_token]
      add_adhearsion_twilio_header!(
        sip_header_util,
        headers,
        "Auth-Token",
        call_variables[:auth_token]
      )
    end

    headers
  end

  def add_adhearsion_twilio_header!(sip_header_util, headers, name, value)
    headers.merge!(
     sip_header_util.construct_header_name(name) => value
    ) if value
  end

  def parse_event(event)
    logger.info("Parsing Event: #{event}")

    sip_header_util = Adhearsion::Twilio::Util::SipHeader.new
    headers = event.headers

    encrypted_auth_token = headers[sip_header_util.construct_header_name("Encrypted-Auth-Token")]
    encrypted_auth_token_iv = headers[sip_header_util.construct_header_name("Encrypted-Auth-Token-IV")]

    if encrypted_auth_token && !encrypted_auth_token.empty? && encrypted_auth_token_iv && !encrypted_auth_token.empty?
      auth_token = decrypt(encrypted_auth_token, encrypted_auth_token_iv)
    else
      logger.warn("Auth token not encrypted! Set AHN_SOMLENG_ENCRYPTION_KEY to encrypt it")
      auth_token = headers[sip_header_util.construct_header_name("Auth-Token")]
    end

    {
      :sip_term_status => headers["variable-sip_term_status"],
      :call_duration => headers["variable-billsec"],
      :answer_epoch => headers["variable-answer_epoch"],
      :status_callback_url => headers[sip_header_util.construct_header_name("Status-Callback-Url")],
      :status_callback_method => headers[sip_header_util.construct_header_name("Status-Callback-Method")],
      :call_sid => headers[sip_header_util.construct_header_name("Call-Sid")],
      :to => headers[sip_header_util.construct_header_name("To")],
      :from => headers[sip_header_util.construct_header_name("From")],
      :direction => headers[sip_header_util.construct_header_name("Direction")],
      :account_sid => headers[sip_header_util.construct_header_name("Account-Sid")],
      :auth_token => auth_token
    }
  end

  def notify_status_callback_url(event_details)
    configuration = Adhearsion::Twilio::Configuration.new
    http_client = Adhearsion::Twilio::HttpClient.new(
      :status_callback_url => event_details[:status_callback_url] || configuration.status_callback_url,
      :status_callback_method => event_details[:status_callback_method] || configuration.status_callback_method,
      :call_sid => event_details[:call_sid],
      :call_to => event_details[:to],
      :call_from => event_details[:from],
      :account_sid => event_details[:account_sid],
      :auth_token => event_details[:auth_token],
      :call_direction => event_details[:direction],
      :logger => logger
    )

    request_options = {}

    request_options.merge!(
      "CallDuration" => event_details[:call_duration]
    ) if event_details[:call_duration]

    request_options.merge!(
      "SipResponseCode" => event_details[:sip_term_status]
    ) if event_details[:sip_term_status]

    call_status = get_adhearsion_twilio_call_status(event_details)
    http_client.notify_status_callback_url(call_status, request_options)
  end

  def call_direction
    "outbound_api"
  end

  def get_routing_instructions(call_params)
    call_params["routing_instructions"] || {}
  end

  def controller_metadata(call_variables)
    {
      :voice_request_url => call_variables[:voice_request_url],
      :voice_request_method => call_variables[:voice_request_method],
      :status_callback_url => call_variables[:status_callback_url],
      :status_callback_method => call_variables[:status_callback_method],
      :account_sid => call_variables[:account_sid],
      :auth_token => call_variables[:auth_token],
      :call_sid => call_variables[:call_sid],
      :adhearsion_twilio_to => call_variables[:adhearsion_twilio_to],
      :adhearsion_twilio_from => call_variables[:adhearsion_twilio_from],
      :call_direction => call_variables[:call_direction],
      :rest_api_enabled => false
    }
  end

  def get_call_variables(call_params)
    routing_instructions = get_routing_instructions(call_params)

    voice_request_url = call_params["voice_url"]
    voice_request_method = call_params["voice_method"]
    status_callback_url = call_params["status_callback_url"]
    status_callback_method = call_params["status_callback_method"]
    account_sid = call_params["account_sid"]
    auth_token = call_params["account_auth_token"]
    call_sid = call_params["sid"]
    caller_id = routing_instructions["source"] || call_params["from"] || default_caller_id
    address = routing_instructions["address"]
    destination = routing_instructions["destination"] || call_params["to"] || default_destination
    destination_host = routing_instructions["destination_host"] || default_destination_host
    gateway = routing_instructions["gateway"] || default_gateway
    gateway_type = routing_instructions["gateway_type"] || default_gateway_type
    dial_string_path = routing_instructions["dial_string_path"] || default_dial_string_path
    dial_string_format = routing_instructions["dial_string_format"] || default_dial_string_format
    dial_string = routing_instructions["dial_string"] || default_dial_string || generate_dial_string(
      dial_string_format, destination, gateway_type, destination_host, gateway, address, dial_string_path
    )
    disable_originate = routing_instructions["disable_originate"] || default_disable_originate

    number_normalizer = Adhearsion::Twilio::Util::NumberNormalizer.new
    adhearsion_twilio_from = number_normalizer.normalize(caller_id)
    adhearsion_twilio_to = number_normalizer.normalize(destination)

    if encrypt_auth_token?
      encrypted_auth_token, encrypted_auth_token_iv = encrypt(auth_token)
    end

    {
      :voice_request_url => voice_request_url,
      :voice_request_method => voice_request_method,
      :status_callback_url => status_callback_url,
      :status_callback_method => status_callback_method,
      :account_sid => account_sid,
      :auth_token => auth_token,
      :encrypted_auth_token => encrypted_auth_token,
      :encrypted_auth_token_iv => encrypted_auth_token_iv,
      :call_sid => call_sid,
      :caller_id => caller_id,
      :destination => destination,
      :destination_host => destination_host,
      :gateway => gateway,
      :dial_string_format => dial_string_format,
      :dial_string => dial_string,
      :adhearsion_twilio_from => adhearsion_twilio_from,
      :adhearsion_twilio_to => adhearsion_twilio_to,
      :call_direction => call_direction,
      :disable_originate => disable_originate,
    }
  end

  def generate_dial_string(dial_string_format, destination, gateway_type, destination_host, gateway, address, dial_string_path)
    dial_string_format.sub(
      /\%\{destination\}/, destination.to_s
    ).sub(
       /\%\{gateway_type\}/, gateway_type.to_s
    ).sub(
      /\%\{destination_host\}/, destination_host.to_s
    ).sub(
      /\%\{gateway\}/, gateway.to_s
    ).sub(
      /\%\{address\}/, address.to_s
    ).sub(
      /\%\{dial_string_path\}/, dial_string_path.to_s
    )
  end

  def encrypt(value)
    aes = OpenSSL::Cipher::Cipher.new(encryption_algorithm)
    iv = OpenSSL::Cipher::Cipher.new(encryption_algorithm).random_iv
    aes.encrypt
    aes.key = encryption_key_digest
    aes.iv = iv
    cipher = aes.update(value)
    cipher << aes.final
    [Base64.encode64(cipher), Base64.encode64(iv)]
  end

  def decrypt(html_escaped_base64_value, html_escaped_base64_iv)
    decode_cipher = OpenSSL::Cipher::Cipher.new(encryption_algorithm)
    decode_cipher.decrypt
    decode_cipher.key = encryption_key_digest
    decode_cipher.iv = Base64.decode64(CGI.unescapeHTML(html_escaped_base64_iv))
    plain = decode_cipher.update(Base64.decode64(CGI.unescapeHTML(html_escaped_base64_value)))
    plain << decode_cipher.final
    plain
  end

  def encryption_key_digest
    digest = Digest::SHA256.new
    digest.update(encryption_key)
    digest.digest
  end

  def encryption_algorithm
    "AES-256-CBC"
  end

  def encrypt_auth_token?
    !!encryption_key
  end

  def encryption_key
    ENV["AHN_SOMLENG_ENCRYPTION_KEY"]
  end

  def default_destination
    ENV["AHN_SOMLENG_DEFAULT_DESTINATION"]
  end

  def default_destination_host
    ENV["AHN_SOMLENG_DEFAULT_DESTINATION_HOST"]
  end

  def default_dial_string
    ENV["AHN_SOMLENG_DEFAULT_DIAL_STRING"]
  end

  def default_dial_string_path
    ENV["AHN_SOMLENG_DEFAULT_DIAL_STRING_PATH"]
  end

  def default_gateway_type
    ENV["AHN_SOMLENG_DEFAULT_GATEWAY_TYPE"]
  end

  def default_gateway
    ENV["AHN_SOMLENG_DEFAULT_GATEWAY"]
  end

  def default_dial_string_format
    ENV["AHN_SOMLENG_DEFAULT_DIAL_STRING_FORMAT"] || DEFAULT_DIAL_STRING_FORMAT
  end

  def default_caller_id
    ENV["AHN_SOMLENG_DEFAULT_CALLER_ID"]
  end

  def default_disable_originate
    ENV["AHN_SOMLENG_DISABLE_ORIGINATE"]
  end
end
