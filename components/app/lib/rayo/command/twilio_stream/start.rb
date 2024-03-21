module Rayo
  module Command
    module TwilioStream
      class Start < Base
        COMMAND_NAME = "start".freeze

        attribute :url

        private

        def command_name
          COMMAND_NAME
        end

        def command_args
          [url]
        end
      end
    end
  end
end
