AWSRequests = Class.new(Array).new
AWSRequest = Struct.new(:context, :operation_name, keyword_init: true)

Aws.config[:ecs] = {
  stub_responses: {
    describe_container_instances: lambda { |_context|
      {
        container_instances: [
          ec2_instance_id: "ec2-instance-id"
        ]
      }
    },
    list_clusters: ->(context) {
      {
        cluster_arns: [ "arn:aws:ecs:#{context.client.config.region}:123456789012:cluster/cluster-1" ]
      }
    },
    list_tasks: ->(context) {
      {
        task_arns: [ "arn:aws:ecs:#{context.client.config.region}:123456789012:task/cluster-1/#{SecureRandom.uuid.gsub('-', '')}" ]
      }
    },
    describe_tasks: ->(context) {
      {
        tasks: [
          {
            attachments: [
              {
                type: "ElasticNetworkInterface",
                details: [
                  {
                    name: "privateIPv4Address",
                    value: "10.10.1.180"
                  }
                ]
              }
            ],
            task_arn: "arn:aws:ecs:#{context.client.config.region}:123456789012:task/cluster-1/#{SecureRandom.uuid.gsub('-', '')}",
            cluster_arn: "arn:aws:ecs:#{context.client.config.region}:123456789012:cluster/cluster-1"
          }
        ]
      }
    },
    stop_task: ->(context) {
      AWSRequests << AWSRequest.new(context:, operation_name: :stop_task)
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
