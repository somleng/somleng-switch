require_relative "../spec_helper"

RSpec.describe "Convert MP3" do
  it "converts a wave file to mp3" do
    bucket = {
      "recording.wav" => file_fixture("recording.wav")
    }

    Aws.config[:s3] = {
      stub_responses: {
        get_object: ->(_context) { { body: File.open(bucket.fetch("recording.wav")) } },
        put_object: ->(context) { bucket[context.params[:key]] = { body: context.params.fetch(:body) }; {} }
      }
    }

    invoke_lambda(bucket: "bucket", object_key: "recording.wav")

    expect(bucket).to have_key("recording.mp3")
  end

  def file_fixture(filename)
    Pathname(File.expand_path("../fixtures/#{filename}", __dir__))
  end
end
