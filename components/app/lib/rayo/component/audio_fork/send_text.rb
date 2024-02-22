module Rayo
  module Component
    module AudioFork
      class SendText < Base
        COMMAND_NAME = "send_text".freeze

        private

        def command_name
          COMMAND_NAME
        end
      end
    end
  end
end
