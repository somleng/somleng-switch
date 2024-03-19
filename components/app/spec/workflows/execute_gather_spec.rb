require "spec_helper"

RSpec.describe ExecuteGather, type: :call_controller do
  it "raises an error with invalid nested verbs" do
    twiml = <<~TWIML
      <?xml version="1.0" encoding="UTF-8" ?>
      <Response>
        <Gather>
          <Record/>
        </Gather>
      </Response>
    TWIML

    expect { ExecuteGather.call(**build_workflow_options(twiml:)) }.to raise_error(Errors::TwiMLError)
  end

  def build_workflow_options(**options)
    context = options.fetch(:context) { build_controller }

    {
      context:,
      call_properties: build_call_properties,
      phone_call: context.call,
      call_platform_client: context.call_platform_client,
      **options
    }
  end
end
