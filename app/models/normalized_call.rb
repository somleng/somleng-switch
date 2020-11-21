class NormalizedCall < SimpleDelegator
  PHONE_NUMBER_PATTERN = /\A\+?\d+\z/.freeze

  attr_reader :call

  def initialize(call)
    @call = call
    super
  end

  def from
    @from ||= normalize_from
  end

  def to
    @to ||= normalize_number(call.to)
  end

  private

  def normalize_from
    result = normalize_number(call.from)
    return result if valid_number?(result)

    normalized_p_asserted_identity = normalize_number(
      call.variables["variable_sip_p_asserted_identity"]
    )
    valid_number?(normalized_p_asserted_identity) ? normalized_p_asserted_identity : result
  end

  def normalize_number(number)
    return if number.blank?

    # remove port if and scheme if given
    result = number.gsub(/(\d+)\:\d+/, '\1').gsub(/^[a-z]+\:/, "")
    result = Mail::Address.new(result).local
    result = result.split("/").last
    result.delete("+")
  end

  def valid_number?(number)
    number =~ PHONE_NUMBER_PATTERN
  end
end
