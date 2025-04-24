require "faraday"

module CallPlatform
  class Client
    attr_reader :http_client

    def initialize(**options)
      @http_client = options.fetch(:http_client) { default_http_client(**options.fetch(:http_client_options, {})) }
    end

    def update_switch_capacity(params)
      notify_request("/services/switch_capacities", params)
    end

    private

    def notify_request(url, params)
      response = http_client.post(url, params.to_json)

      unless response.success?
        Sentry.capture_message("Invalid Request to: #{url}", extra: { response_body: response.body })
      end
    end

    def default_http_client(**options)
      Faraday.new(url: options.fetch(:url, CallPlatform.configuration.host)) do |conn|
        conn.headers["Accept"] = "application/json"
        conn.headers["Content-Type"] = "application/json"

        conn.adapter Faraday.default_adapter

        conn.request(
          :authorization,
          :basic,
          options.fetch(:username, CallPlatform.configuration.username),
          options.fetch(:password, CallPlatform.configuration.password)
        )
      end
    end
  end
end
