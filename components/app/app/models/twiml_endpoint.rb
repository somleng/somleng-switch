class TwiMLEndpoint
  HTTP_METHODS = {
    "GET" => :get,
    "POST" => :post
  }.freeze

  attr_reader :auth_token

  def initialize(options)
    @auth_token = options.fetch(:auth_token)
  end

  def request(url, http_method, call_params)
    uri = resolve_uri(url)
    http_method = HTTP_METHODS.fetch(http_method, :post)

    if http_method == :get
      uri.query_values = uri.query_values(Array).to_a.concat(call_params.to_a)
      self.last_response = http_client.get(
        uri,
        headers: {
          "X-Twilio-Signature" => twilio_signature(uri: uri)
        }
      )
    else
      self.last_response = http_client.post(
        uri,
        form: call_params,
        headers: {
          "X-Twilio-Signature" => twilio_signature(uri: uri, payload: call_params)
        }
      )
    end

    last_response.to_s
  end

  private

  attr_accessor :last_response

  def resolve_uri(url)
    uri = last_response ? URI.join(last_response.uri, url.to_s) : URI(url)
    HTTP::URI.parse(uri)
  end

  def http_client
    @http_client ||= HTTP.follow.headers(
      "Content-Type" => "application/x-www-form-urlencoded; charset=utf-8",
      "User-Agent" => "TwilioProxy/1.1",
      "Accept" => "text/xml, application/xml, text/html",
      "Cache-Control" => "max-age=#{72.hours.seconds}"
    )
  end

  def twilio_signature(uri:, payload: {})
    data = uri.to_s + payload.sort.join
    digest = OpenSSL::Digest.new("sha1")
    Base64.strict_encode64(OpenSSL::HMAC.digest(digest, auth_token, data))
  end
end
