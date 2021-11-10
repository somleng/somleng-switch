module Utils
  DEFAULT_VARIABLES = {
    "sip-force-contact" => "NDLB-connectile-dysfunction"
  }.freeze

  def self.build_dial_string(address, variables = {})
    variables.merge!(DEFAULT_VARIABLES)
    prefix = variables.map { |k, v| "#{k}=#{v}" }.join(",")
    prefix = "{#{prefix}}" if prefix.present?
    "#{prefix}sofia/external/#{address}"
  end
end
