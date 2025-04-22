require "spec_helper"

RSpec.describe HandleSwitchEvent, :public_gateway, :client_gateway do
  it "handles handles running switch events" do
    sqs_client = Aws::SQS::Client.new(stub_responses: true)
    queue_url = "https://sqs.us-east-1.amazonaws.com/123456789/queue"
    event = build_ecs_event(
      task_running?: true,
      region: "ap-southeast-1",
      private_ip: "10.0.0.100",
      cluster: "somleng-switch",
      family: "switch"
    )

    HandleSwitchEvent.call(event:, queue_url:, sqs_client:)

    results = public_gateway_load_balancer.all
    expect(results[0]).to include(
      group_id: 1,
      dst_uri: "sip:10.0.0.100:5060",
      resources: "gw=fs://:fs-event-socket-password@10.0.0.100:8021"
    )
    expect(results[1]).to include(
      group_id: 1,
      dst_uri: "sip:10.0.0.100:5080",
      resources: "gwalt=fs://:fs-event-socket-password@10.0.0.100:8021"
    )
    expect(sqs_client.api_requests.first).to match(
      sqs_request(
        {
          region: "ap-southeast-1",
          cluster: "somleng-switch",
          family: "switch"
        },
        job_class: "NotifySwitchCapacityChangeJob",
        queue_url:
      )
    )
  end

  it "handles switch events from different regions" do
    sqs_client = Aws::SQS::Client.new(stub_responses: true)
    event = build_ecs_event(
      task_running?: true,
      region: "us-east-1"
    )

    HandleSwitchEvent.call(event:, sqs_client:)

    results = public_gateway_load_balancer.all
    expect(results[0]).to include(
      group_id: 2
    )
    expect(sqs_client.api_requests.size).to eq(1)
  end

  it "handles stopped switch events" do
    create_load_balancer_target(
      dst_uri: "sip:10.1.1.100:5060",
      resources: "gw=fs://:fs-event-socket-password@10.1.1.100:8021"
    )
    sqs_client = Aws::SQS::Client.new(stub_responses: true)
    event = build_ecs_event(task_running?: false, task_stopped?: true, private_ip: "10.1.1.100")

    HandleSwitchEvent.call(event:, sqs_client:)

    expect(public_gateway_load_balancer.count).to eq(0)
    expect(sqs_client.api_requests.size).to eq(1)
  end

  def public_gateway_load_balancer
    public_gateway_database_connection.table(:load_balancer)
  end

  def sqs_request(*args, **options)
    hash_including(
      operation_name: :send_message,
      params: hash_including(
        queue_url: options.fetch(:queue_url) { AppSettings.fetch(:queue_url) },
        message_body: {
          job_class: options.fetch(:job_class),
          job_args: args
        }.to_json
      )
    )
  end
end
