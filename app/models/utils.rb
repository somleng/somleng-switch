module Utils
  DEFAULT_VARIABLES = {}.freeze

  def self.build_dial_string(address, variables = {})
    variables.merge!(DEFAULT_VARIABLES)
    vars = variables.map { |k, v| "#{k}=#{v}" }.join(",")
    vars = "{#{prefix}}" if vars.present?
    "#{vars}sofia/external/#{address}"
  end
end
