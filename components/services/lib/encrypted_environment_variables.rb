require "aws-sdk-ssm"

class EncryptedEnvironmentVariables
  attr_reader :ssm_client, :environment

  SSM_PARAMETER_NAME_PATTERN = "_SSM_PARAMETER_NAME".freeze

  def initialize(ssm_client: Aws::SSM::Client.new, environment: ENV)
    @ssm_client = ssm_client
    @environment = environment
  end

  def decrypt
    return if ssm_parameter_names.empty?

    decryption_result = decrypt_parameters(ssm_parameter_names.values)
    set_env_from_parameters(decryption_result.parameters)
  end

  private

  def ssm_parameter_names
    @ssm_parameter_names ||= environment.select { |key, _| key.end_with?(SSM_PARAMETER_NAME_PATTERN) }
  end

  def decrypt_parameters(names)
    ssm_client.get_parameters(names:, with_decryption: true)
  end

  def set_env_from_parameters(parameters)
    ssm_parameter_names.each do |name, value|
      env_name = name.delete_suffix(SSM_PARAMETER_NAME_PATTERN)
      environment[env_name] = parameters.find { |parameter| parameter.name == value }.value
    end
  end
end
