require 'spec_helper'
require 'adhearsion/twilio/spec/helpers'

describe CallController do
  include Adhearsion::Twilio::Spec::Helpers

  subject { CallController.new(mock_call) }

  describe "#run" do
    it "should make a request to fetch the Twiml" do
      expect_call_status_update(:assert_answered => false) { subject.run }
    end
  end
end
