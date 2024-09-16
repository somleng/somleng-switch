if %w[development test].include?(AppSettings.env)
  Aws.config[:ssm] = {
    stub_responses: {
      get_parameters: lambda { |context|
        {
          parameters: context.params[:names].map do |name|
            Aws::SSM::Types::Parameter.new(
              name:,
              value: name.delete_prefix("ssm-parameter-name-")
            )
          end
        }
      }
    }
  }
end
