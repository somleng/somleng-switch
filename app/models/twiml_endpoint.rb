class TwiMLEndpoint
  HTTP_METHODS = {
    "GET" => :get,
    "POST" => :post
  }.freeze

  attr_reader :auth_token, :last_response

  def initialize(options)
    @auth_token = options.fetch(:auth_token)
  end

  def request(url, http_method, params)
    url = resolve_url(url)
    http_method = HTTP_METHODS.fetch(http_method, :post)

    @last_response = http_client.run_request(
      http_method,
      url,
      params.to_query,
      "x-twilio-signature" => twilio_signature(
        url: url,
        params: params
      )
    )

    parse_twiml(last_response.body)
  end

  private

  def resolve_url(url)
    uri = @last_response ? URI.join(@last_response.env.url, url.to_s) : URI(url)
    uri.query = Faraday::Utils.sort_query_params(uri.query)
    uri.to_s
  end

  def http_client
    @http_client ||= Faraday.new do |conn|
      conn.headers["content-type"] = "application/x-www-form-urlencoded; charset=utf-8"
      conn.headers["user-agent"] = "TwilioProxy/1.1"
      conn.headers["accept"] = "*/*"
      conn.headers["cache-control"] = "max-age=#{72.hours.seconds}"

      conn.use FaradayMiddleware::FollowRedirects
      conn.adapter Faraday.default_adapter
    end
  end

  def twilio_signature(url:, params:)
    data = url + params.sort.join
    digest = OpenSSL::Digest.new("sha1")
    Base64.strict_encode64(OpenSSL::HMAC.digest(digest, auth_token, data))
  end

  def parse_twiml(content)
    doc = ::Nokogiri::XML(content.strip) do |config|
      config.options = Nokogiri::XML::ParseOptions::NOBLANKS
    end

    raise(Errors::TwiMLError, "The root element must be the '<Response>' element") if doc.root.name != "Response"

    doc.root.children
  rescue Nokogiri::XML::SyntaxError => e
    raise Errors::TwiMLError, "Error while parsing XML: #{e.message}. XML Document: #{content}"
  end
end
