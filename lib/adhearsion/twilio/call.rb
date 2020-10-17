require_relative "util/number_normalizer"

class Adhearsion::Twilio::Call
  attr_accessor :call, :to, :from

  def initialize(call)
    self.call = call
    set_call_variables!
  end

  def id
    call.id
  end

  def duration
    call.duration.to_i
  end

  def variables
    call.variables
  end

  private

  def number_normalizer
    @number_normalizer ||= Adhearsion::Twilio::Util::NumberNormalizer.new
  end

  def set_call_variables!
    normalize_from!
    normalize_to!
  end

  def normalize_from!
    from = number_normalizer.normalize(call.from)
    if !number_normalizer.valid?(from)
      normalized_p_asserted_identity = number_normalizer.normalize(
        call.variables["variable_sip_p_asserted_identity"]
      )
      from = normalized_p_asserted_identity if number_normalizer.valid?(normalized_p_asserted_identity)
    end
    self.from = from
  end

  def normalize_to!
    self.to = number_normalizer.normalize(call.to)
  end
end
