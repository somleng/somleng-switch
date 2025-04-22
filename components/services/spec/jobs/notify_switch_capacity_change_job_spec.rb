require "spec_helper"

RSpec.describe NotifySwitchCapacityChangeJob do
  it "fetches the number of tasks and notifies Somleng" do
    task_arns = [ "task-arn-1", "task-arn-2" ]
    ecs_client = stub_ecs_client(task_arns)
    somleng_client = instance_spy(Somleng::Client)

    job = NotifySwitchCapacityChangeJob.new(
      {
        region: "ap-southeast-1",
        cluster: "somleng-switch",
        family: "switch"
      },
      ecs_client:,
      somleng_client:
    )

    job.call

    expect(ecs_client.api_requests.first).to match(
      list_tasks_request(
        cluster: "somleng-switch",
        family: "switch"
      )
    )
    expect(somleng_client).to have_received(:update_switch_capacity).with(
      region: "hydrogen",
      capacity: 2
    )
  end

  it "instantiates the ECS client with the correct region" do
    job = NotifySwitchCapacityChangeJob.new(
      {
        region: "us-east-1",
        cluster: "somleng-switch",
        family: "switch"
      }
    )

    expect(job.ecs_client.config.region).to eq("us-east-1")
  end

  def stub_ecs_client(task_arns)
    Aws::ECS::Client.new(
      stub_responses: {
        list_tasks: Aws::ECS::Client.new.stub_data(:list_tasks, task_arns: Array(task_arns))
      }
    )
  end

  def list_tasks_request(**options)
    hash_including(
      operation_name: :list_tasks,
      params: hash_including(
        cluster: options.fetch(:cluster),
        family: options.fetch(:family)
      )
    )
  end
end
