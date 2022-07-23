require "aws-sdk-ssm"

class DecryptEnvironmentVariables < ApplicationWorkflow
  attr_reader :ssm_client

  SSM_PARAMETER_NAME_PATTERN = "_SSM_PARAMETER_NAME".freeze

  def initialize(ssm_client: Aws::SSM::Client.new)
    @ssm_client = ssm_client
  end

  def call
    return if ssm_parameter_names.empty?

    decryption_result = decrypt_parameters(ssm_parameter_names.values)
    set_env_from_parameters(decryption_result.parameters)
  end

  private

  def ssm_parameter_names
    @ssm_parameter_names ||= ENV.select { |key, _| key.end_with?(SSM_PARAMETER_NAME_PATTERN) }
  end

  def decrypt_parameters(names)
    ssm_client.get_parameters(names:, with_decryption: true)
  end

  def set_env_from_parameters(parameters)
    ssm_parameter_names.each_with_index do |(name, _), i|
      env_name = name.delete_suffix(SSM_PARAMETER_NAME_PATTERN)
      ENV[env_name] = parameters[i].value
    end
  end
end
