Aws.config[:ssm] = {
  stub_responses: {
    get_parameters: lambda { |context|
      {
        parameters: context.params[:names].map do |name|
          Aws::SSM::Types::Parameter.new(value: name.delete_prefix("ssm-parameter-name-"))
        end
      }
    }
  }
}
