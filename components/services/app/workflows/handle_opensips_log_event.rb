class HandleOpenSIPSLogEvent < ApplicationWorkflow
  LOAD_BALANCER_RESPONSE_ERROR_PATTERN = %r{\A(\d{3})-lb-response-error-(((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4})\z}
  TIMEOUT_ERROR_CODE = "408"

  attr_reader :event, :error_tracking_client

  LoadBalancerError = Struct.new(:target_ip, :code, keyword_init: true)

  def initialize(event:, error_tracking_client: Sentry)
    @event = event
    @error_tracking_client = error_tracking_client
  end

  def call
    p "handling event: #{event}"
    p "load_balancer_response_errors: #{load_balancer_response_errors}"
    if load_balancer_response_errors.any?
      error_messages = load_balancer_response_errors.map do |error|
        "Error detected on load balancer: #{error.target_ip} - #{error.code}"
      end
      error_tracking_client.capture_message(error_messages.join("\n"))
    else
      error_messages = opensips_logs.each do |log|
        log.message
      end

      error_tracking_client.capture_message(error_messages.join("\n"))
    end
  end

  def opensips_logs
    @opensips_logs ||= OpenSIPSLogEventParser.new(event).parse_event
  end

  def load_balancer_response_errors
    @load_balancer_response_errors ||= begin
      errors = opensips_logs.select do |log|
        log.message.match?(LOAD_BALANCER_RESPONSE_ERROR_PATTERN)
      end

      errors.map do |log|
        code, ip, = LOAD_BALANCER_RESPONSE_ERROR_PATTERN.match(log.message).captures
        LoadBalancerError.new(target_ip: IPAddr.new(ip), code:)
      end
    end
  end

  def find_errors_by_code(code)
    load_balancer_response_errors.select { |error| error.code == code }
  end
end
