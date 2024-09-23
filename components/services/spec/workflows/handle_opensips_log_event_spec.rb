require_relative "../spec_helper"

RSpec.describe HandleOpenSIPSLogEvent do
  it "handles OpenSIPS log events" do
    events = [
      build_event(message: "408-lb-response-error-10.10.1.180"),
      build_event(message: "408-lb-response-error-10.10.1.180"),
      build_event(message: "408-lb-response-error-10.20.1.150"),
      build_event(message: "500-lb-response-error-10.10.1.181"),
      build_event(message: "Some other error")
    ]

    fake_task_finder = stub_task_finder(
      { arn: "task-1-arn", region: "ap-southeast-1", cluster: "cluster-1-arn" },
      { arn: "task-2-arn", region: "us-east-1", cluster: "cluster-2-arn" }
    )

    ecs_client, requested_regions = stub_ecs_client
    error_tracking_client = class_spy(Sentry)

    HandleOpenSIPSLogEvent.call(event: events, error_tracking_client:, ecs_client:, ecs_task_finder: fake_task_finder)

    stop_task_requests = aws_requests(ecs_client, :stop_task)
    expect(stop_task_requests.size).to eq(2)
    expect(stop_task_requests[0].fetch(:params)).to eq(
      cluster: "cluster-1-arn",
      task: "task-1-arn",
      reason: "Load balancer timeout detected"
    )
    expect(stop_task_requests[1].fetch(:params)).to include(
      cluster: "cluster-2-arn",
      task: "task-2-arn"
    )
    expect(requested_regions).to contain_exactly("ap-southeast-1", "us-east-1")
    expect(error_tracking_client).to have_received(:capture_message).with(
      [
        "408-lb-response-error-10.10.1.180",
        "408-lb-response-error-10.20.1.150",
        "500-lb-response-error-10.10.1.181",
        "Some other error"
      ].join("\n")
    )
  end

  def build_event(message:)
    OpenSIPSLogEventParser::Event.new(message:)
  end

  def stub_task_finder(*task_results)
    fake_task_finder = class_double(FindECSTask)
    task_results = task_results.map { |data| build_task_result(**data) }
    allow(fake_task_finder).to receive(:call).and_return(*task_results)
    fake_task_finder
  end

  def stub_ecs_client
    requested_regions = []
    client = Aws::ECS::Client.new(
      stub_responses: {
        stop_task: ->(context) {
          requested_regions << context.client.config.region
        }
      }
    )

    [ client, requested_regions ]
  end

  def build_task_result(region: "us-east-1", **options)
    FindECSTask::Task.new(
      region:,
      arn: "arn:aws:ecs:#{region}:123456789012:task/cluster-1/#{SecureRandom.uuid.gsub('-', '')}",
      cluster: "arn:aws:ecs:#{region}:123456789012:cluster/cluster-1",
      private_ip: "10.0.0.1",
      **options
    )
  end

  def aws_requests(client, operation_name)
    client.api_requests.select { |request| request[:operation_name] == operation_name }
  end
end
