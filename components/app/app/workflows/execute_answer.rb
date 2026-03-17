class ExecuteAnswer < ApplicationWorkflow
  attr_reader :context, :call_properties, :phone_call

  def initialize(context:, call_properties:, phone_call:)
    super()
    @context = context
    @call_properties = call_properties
    @phone_call = phone_call
  end

  def call
    answer unless answered?
  end

  private

  def answer
    context.answer(call_properties.sip_headers.response_headers)
  end

  def answered?
    return false if phone_call.blank?

    phone_call.answer_time.present?
  end
end
