class StopTwilioStream < ApplicationWorkflow
  attr_reader :call_controller, :phone_call

  def initialize(call_controller)
    super()
    @call_controller = call_controller
    @phone_call = call_controller.call
  end

  def call
    call_controller.write_and_await_response(Rayo::Command::TwilioStream::Stop.new(uuid: phone_call.id))
    DisconnectTwilioStream.call(call_controller)
  end
end
