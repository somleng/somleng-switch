class UpdateCallJob
  include SuckerPunch::Job

  def perform(call_controller)
    call_controller.run
  end
end
