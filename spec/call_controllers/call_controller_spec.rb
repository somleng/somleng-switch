require "spec_helper"

describe CallController do
  describe "#run" do
    it "handles the call via adhearsion-twilio" do
      call = instance_double(Adhearsion::Call)
      call_controller = described_class.new(call)
      allow(call_controller).to receive(:notify_voice_request_url)

      call_controller.run

      expect(call_controller).to have_received(:notify_voice_request_url)
    end
  end
end
