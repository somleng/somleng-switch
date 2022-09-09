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

Aws.config[:ecs] = {
  stub_responses: {
    describe_container_instances: lambda { |_context|
      {
        container_instances: [
          ec2_instance_id: "ec2-instance-id"
        ]
      }
    }
  }
}

Aws.config[:ec2] = {
  stub_responses: {
    describe_instances: lambda { |_context|
      {
        reservations: [
          instances: [
            private_ip_address: "10.0.0.1"
          ]
        ]
      }
    }
  }
}
