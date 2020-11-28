class TwiMLEndpoint
  HTTP_METHODS = {
    "GET" => :get,
    "POST" => :post
  }.freeze

  attr_reader :url, :http_method, :auth_token

  def initialize(options)
    @url = options.fetch(:url)
    @http_method = HTTP_METHODS.fetch(options.fetch(:http_method) || "POST")
    @auth_token = options.fetch(:auth_token)
  end

  def request(params)
    http_client.run_request(
      http_method,
      url,
      params.to_query,
      "x-twilio-signature" => twilio_signature(
        url: url,
        auth_token: auth_token,
        params: params
      )
    )
  end

  private

  def http_client
    @http_client ||= Faraday.new do |conn|
      conn.headers["content-type"] = "application/x-www-form-urlencoded; charset=utf-8"
      conn.headers["user-agent"] = "TwilioProxy/1.1"
      conn.headers["accept"] = "*/*"
      conn.headers["cache-control"] = "max-age=#{72.hours.seconds}"

      conn.adapter Faraday.default_adapter
    end
  end

  def twilio_signature(url:, auth_token:, params:)
    data = url + params.sort.join
    digest = OpenSSL::Digest.new("sha1")
    Base64.encode64(OpenSSL::HMAC.digest(digest, auth_token, data)).strip
  end
end
