module Rayo
  module Command
    module TwilioStream
      class Start < Base
        COMMAND_NAME = "start".freeze

        attribute :url
        attribute :metadata

        private

        def command_name
          COMMAND_NAME
        end

        def command_args
          [ url, Base64.urlsafe_encode64(metadata.to_json) ]
        end
      end
    end
  end
end
