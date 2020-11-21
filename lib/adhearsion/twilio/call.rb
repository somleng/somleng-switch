require_relative "util/number_normalizer"

class Adhearsion::Twilio::Call
  attr_reader :call

  delegate :id, :variables, to: :call

  def initialize(call)
    @call = call
  end

  def duration
    call.duration.to_i
  end

  def from
    @from ||= normalize_from
  end

  def to
    @to ||= number_normalizer.normalize(call.to)
  end

  private

  def number_normalizer
    @number_normalizer ||= Adhearsion::Twilio::Util::NumberNormalizer.new
  end

  def normalize_from
    result = number_normalizer.normalize(call.from)
    return result if number_normalizer.valid?(result)

    normalized_p_asserted_identity = number_normalizer.normalize(
      variables["variable_sip_p_asserted_identity"]
    )
    number_normalizer.valid?(normalized_p_asserted_identity) ? normalized_p_asserted_identity : result
  end
end
