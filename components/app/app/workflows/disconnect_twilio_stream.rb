class DisconnectTwilioStream < ApplicationWorkflow
  attr_reader :call_controller, :phone_call

  def initialize(call_controller)
    super()
    @call_controller = call_controller
    @phone_call = call_controller.call
  end

  def call
    phone_call.write_command(Rayo::Command::UpdateCallProgress.new(flag: 0))
  end
end
