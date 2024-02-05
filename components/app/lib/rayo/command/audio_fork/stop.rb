module Rayo
  module Command
    module AudioFork
      class Stop < Base
        COMMAND_NAME = "stop".freeze

        private

        def command_name
          COMMAND_NAME
        end
      end
    end
  end
end
