class StartTwilioStream < ApplicationWorkflow
  attr_reader :call_controller, :phone_call, :call_properties, :url, :stream_sid, :custom_parameters

  def initialize(call_controller, **options)
    super()
    @call_controller = call_controller
    @phone_call = call_controller.call
    @call_properties = options.fetch(:call_properties)
    @url = options.fetch(:url)
    @stream_sid = options.fetch(:stream_sid)
    @custom_parameters = options.fetch(:custom_parameters)
  end

  def call
    call_controller.write_and_await_response(
      Rayo::Command::TwilioStream::Start.new(
        uuid: phone_call.id,
        url:,
        metadata: {
          call_sid: call_properties.call_sid,
          account_sid: call_properties.account_sid,
          stream_sid:,
          custom_parameters:
        }
      )
    )
    phone_call.write_command(Rayo::Command::UpdateCallProgress.new(flag: 1))
  end
end
