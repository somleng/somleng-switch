require_relative "resource"

class Adhearsion::Twilio::RestApi::PhoneCall < Adhearsion::Twilio::RestApi::Resource
  def twilio_call
    options[:twilio_call]
  end

  def voice_request_url
    fetch_remote(:voice_url)
  end

  def voice_request_method
    fetch_remote(:voice_method)
  end

  def status_callback_url
    fetch_remote(:status_callback_url)
  end

  def status_callback_method
    fetch_remote(:status_callback_method)
  end

  def account_sid
    fetch_remote(:account_sid)
  end

  def auth_token
    fetch_remote(:account_auth_token)
  end

  def call_sid
    fetch_remote(:sid)
  end

  def from
    fetch_remote(:from)
  end

  def to
    fetch_remote(:to)
  end

  def direction
    fetch_remote(:direction)
  end

  def api_version
    fetch_remote(:api_version)
  end

  def twilio_request_to
    fetch_remote(:twilio_request_to)
  end

  private

  def whitelisted_call_variables
    call_variables = {}
    optional_merge!(call_variables, "sip_from_host", twilio_call.variables["variable_sip_from_host"])
    optional_merge!(call_variables, "sip_to_host", twilio_call.variables["variable_sip_to_host"])
    optional_merge!(call_variables, "sip_network_ip", twilio_call.variables["variable_sip_network_ip"])
    call_variables
  end

  def optional_merge!(hash, key, value)
    hash.merge!(key => value) if value && !value.empty?
  end

  def created?
    @remote_response && @remote_response.success?
  end

  def fetch_remote(attribute)
    (remote_response && created? && remote_response[attribute.to_s]).presence
  end

  def remote_response
    @remote_response ||= create_remote_phone_call!
  end

  def create_remote_phone_call!
    basic_auth, url = extract_auth(configuration.rest_api_phone_calls_url)

    request_options = {
      :body => {
        "From" => twilio_call.from,
        "To" => twilio_call.to,
        "ExternalSid" => twilio_call.id,
        "Variables" => whitelisted_call_variables
      }
    }

    request_options.merge!(:basic_auth => basic_auth) if basic_auth.any?

    log(:info, "POSTING to Twilio REST API at: #{url} with options: #{request_options}")

    @remote_response = HTTParty.post(url, request_options)
  end
end
