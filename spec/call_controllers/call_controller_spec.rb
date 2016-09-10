require 'spec_helper'

describe CallController do
  subject { described_class.new(mock_call) }
  let(:mock_call) { double("Call") }

  describe "#run" do
    def setup_scenario
      allow(subject).to receive(:notify_voice_request_url)
    end

    def setup_expectations
      expect(subject).to receive(:notify_voice_request_url)
    end

    def assert_adhearsion_twilio_handled!
      setup_expectations
      subject.run
    end

    before do
      setup_scenario
    end

    it { assert_adhearsion_twilio_handled! }
  end
end
