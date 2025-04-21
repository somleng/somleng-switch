class HandleSQSMessageEvent < ApplicationWorkflow
  attr_reader :event

  def initialize(event:)
    super()
    @event = event
  end

  def call
    event.records.each do |record|
      record.job_class.new(*record.job_args).call
    end
  end
end
