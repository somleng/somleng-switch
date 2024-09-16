require "aws-sdk-s3"
require "open3"
require "securerandom"

require_relative "config/application"

module App
  class Handler
    attr_reader :event, :context, :s3_client

    def self.process(event:, context:)
      new(event:, context:).process
    end

    def initialize(event:, context:, s3_client: Aws::S3::Client.new)
      @event = event
      @context = context
      @s3_client = s3_client
    end

    def process
      tempfile do |raw_file|
        s3_client.get_object(bucket:, key:, response_target: raw_file.path)

        tempfile(convert_to_extension) do |converted_file|
          convert_file(raw_file, converted_file)

          s3_client.put_object(bucket:, key: converted_file_key.to_s, body: File.open(converted_file))
        end
      end
    end

    private

    def tempfile(extension = nil, &block)
      Tempfile.create([ SecureRandom.uuid, extension ].compact, &block)
    end

    def convert_file(raw_file, converted_file)
      _stdout_str, error_str, status = Open3.capture3("ffmpeg", "-y", "-i", raw_file.path, converted_file.path)
      raise StandardError, error_str unless status.success?
    end

    def converted_file_key
      Pathname(key).sub_ext(convert_to_extension)
    end

    def bucket
      s3.dig("bucket", "name")
    end

    def key
      CGI.unescape(s3.dig("object", "key"))
    end

    def s3
      event.dig("Records", 0, "s3")
    end

    def convert_to_extension
      ENV.fetch("CONVERT_TO_EXTENSION", ".mp3")
    end
  end
end
