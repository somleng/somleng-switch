module Rayo
  module Command
    module AudioFork
      class Start < Base
        COMMAND_NAME = "start".freeze

        attribute :url
        attribute :mix_type
        attribute :sampling_rate

        private

        def command_name
          COMMAND_NAME
        end

        def command_args
          [url, mix_type, sampling_rate]
        end
      end
    end
  end
end
