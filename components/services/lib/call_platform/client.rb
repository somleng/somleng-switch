require "faraday"

module CallPlatform
  class Client
    attr_reader :http_client, :capture_errors, :error_handler

    def initialize(**options)
      @http_client = options.fetch(:http_client) { default_http_client(**options.fetch(:http_client_options, {})) }
      @capture_errors = options.fetch(:capture_errors) { AppSettings.env == "production" }
      @error_handler = options.fetch(:error_handler) { Sentry }
    end

    def update_capacity(params)
      notify_request("/services/call_service_capacities", params)
    end

    private

    def notify_request(url, params)
      response = http_client.post(url, params.to_json)

      if !response.success? && capture_errors
        error_handler.capture_message("Invalid Request to: #{url}", extra: { response_body: response.body })
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
