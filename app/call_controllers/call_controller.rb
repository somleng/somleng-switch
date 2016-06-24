class CallController < Adhearsion::CallController
  include Adhearsion::Twilio::ControllerMethods

  def run
    notify_voice_request_url
  end
end
