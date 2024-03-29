class ExecuteTwiMLVerb < ApplicationWorkflow
  attr_reader :verb, :context, :call_properties, :call_platform_client, :phone_call

  def initialize(verb, **options)
    super()
    @verb = verb
    @context = options.fetch(:context)
    @call_properties = options.fetch(:call_properties)
    @call_platform_client = options.fetch(:call_platform_client)
    @phone_call = options.fetch(:phone_call)
  end

  private

  def answer!
    ExecuteAnswer.call(context:, call_properties:, phone_call:)
  end
end
