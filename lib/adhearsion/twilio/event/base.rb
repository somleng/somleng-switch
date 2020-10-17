class Adhearsion::Twilio::Event::Base
  attr_accessor :call_id, :params

  def initialize(call_id, params = {})
    self.call_id = call_id
    self.params = params
  end
end
