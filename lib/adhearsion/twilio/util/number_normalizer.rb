class Adhearsion::Twilio::Util::NumberNormalizer
  def normalize(number)
    normalized_destination(number)
  end

  def valid?(number)
    number =~ /\A\+?\d+\z/
  end

  private

  def normalized_destination(raw_destination)
    # remove port if and scheme if given
    destination = raw_destination.gsub(/(\d+)\:\d+/, '\1').gsub(/^[a-z]+\:/, "") if raw_destination
    destination = Mail::Address.new(destination).local
    destination = File.basename(destination.to_s)
    valid?(destination) ? "+#{destination.gsub('+', '')}" : destination
  end
end
