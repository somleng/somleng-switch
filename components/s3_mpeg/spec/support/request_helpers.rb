module RequestHelpers
  def invoke_lambda(bucket:, object_key:)
    context = double("LambdaContext", as_json: {})

    bucket_event = {
      "Records" => [
        {
          "s3" => {
            "bucket" => {
              "name" => bucket
            },
            "object" => {
              "key" => object_key
            }
          }
        }
      ]
    }

    App::Handler.process(event: bucket_event, context: context)
  end
end

RSpec.configure do |config|
  config.include(RequestHelpers)
end
