require "json"

module EventHelpers
  def build_cloudwatch_log_event(data = {})
    data = {
      id: SecureRandom.random_number(10**56).to_s.rjust(56, "0"),
      timestamp: Time.now.to_i * 1000,
      message: "log-message"
    }.merge(data)

    {
      "id" => data.fetch(:id),
      "timestamp" => data.fetch(:timestamp),
      "message" => data.fetch(:message)
    }
  end

  def build_cloudwatch_log_event_payload(data = {})
    data = {
      log_group: "testing",
      log_events: [
        build_cloudwatch_log_event
      ]
    }.merge(data)

    payload = JSON.parse(file_fixture("cloudwatch_log_event.json").read)
    data_message = JSON.parse(Zlib::GzipReader.new(StringIO.new(Base64.decode64(payload.dig("awslogs", "data")))).read)

    overrides = {
      "logGroup" => data.fetch(:log_group),
      "logEvents" => data.fetch(:log_events)
    }

    compressed_data_message = StringIO.new
    gz = Zlib::GzipWriter.new(compressed_data_message)
    gz.write(data_message.merge(overrides).to_json)
    gz.close

    {
      "awslogs" => {
        "data" => Base64.encode64(compressed_data_message.string)
      }
    }
  end

  def build_sqs_message_event_payload(data = {})
    data = {
      event_source_arn: "arn:aws:sqs:us-east-2:123456789012:somleng-switch-permissions",
      body: "{}",
      attributes: {}
    }.merge(data)

    payload = JSON.parse(file_fixture("sqs_message_event.json").read)

    overrides = {
      "Records" => [
        {
          "eventSourceARN" => data.fetch(:event_source_arn),
          "body" => data.fetch(:body),
          "attributes" => data.fetch(:attributes)
        }
      ]
    }

    payload.merge(overrides)
  end

  def build_ecs_event_payload(data = {})
    data = {
      region: "us-west-2",
      eni_private_ip: "10.0.0.1",
      eni_status: "ATTACHED",
      last_status: "RUNNING",
      group: "service:somleng-switch",
      cluster_arn: "arn:aws:ecs:us-west-2:111122223333:cluster/Cluster",
      container_instance_arn: "arn:aws:ecs:us-west-2:111122223333:container-instance/service/container-instance-id"
    }.merge(data)

    data[:attachment_details] ||= [
      {
        "name" => "privateIPv4Address",
        "value" => data.fetch(:eni_private_ip)
      }
    ]

    data[:attachments] ||= [
      {
        "type" => "eni",
        "status" => data.fetch(:eni_status),
        "details" => data.fetch(:attachment_details)
      }
    ]

    payload = JSON.parse(file_fixture("task_state_change_event.json").read)

    overrides = {
      "region" => data.fetch(:region),
      "detail" => {
        "attachments" => data.fetch(:attachments),
        "lastStatus" => data.fetch(:last_status),
        "group" => data.fetch(:group),
        "clusterArn" => data.fetch(:cluster_arn),
        "containerInstanceArn" => data.fetch(:container_instance_arn)
      }
    }

    payload.merge(overrides)
  end

  def build_service_action_payload(data = {})
    data = {
      service_action: "BuildClientGatewayDialString",
      parameters: {
        client_identifier: "user1",
        destination: "016701722"
      }
    }.merge(data)

    {
      "serviceAction" => data.fetch(:service_action),
      "parameters" => data.fetch(:parameters)
    }
  end
end

RSpec.configure do |config|
  config.include(EventHelpers)
end
