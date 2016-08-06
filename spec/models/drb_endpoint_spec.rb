require 'spec_helper'

describe DrbEndpoint do
  describe "#initiate_outbound_call!(call_json)" do
    let(:valid_call_json) { "{\"to\":\"+855715100860\",\"from\":\"8552442\",\"status\":\"queued\",\"sid\":\"ae034e12-2d2d-4eb8-8569-2c03fa73ed76\",\"account_sid\":\"4e452615-d888-409b-be34-2cd98db2a440\",\"uri\":\"/api/2010-04-01/Accounts/4e452615-d888-409b-be34-2cd98db2a440/Calls/ae034e12-2d2d-4eb8-8569-2c03fa73ed76\",\"date_created\":\"Tue, 26 Jul 2016 10:45:54 +0000\",\"date_updated\":\"Tue, 26 Jul 2016 10:45:54 +0000\"}" }

    it { subject.initiate_outbound_call!(valid_call_json) }
  end
end
