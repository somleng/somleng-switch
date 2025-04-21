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
            private_ip_address: "10.0.0.1",
            public_ip_address: "54.251.92.249"
          ]
        ]
      }
    }
  }
}

Aws.config[:sqs] ||= {
  stub_responses: {
    send_message: Aws::SQS::Client.new.stub_data(:send_message)
  }
}
