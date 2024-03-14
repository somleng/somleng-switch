module Rayo
  module Command
    module AudioForkTwilio
      class Start < Base
        COMMAND_NAME = "start".freeze

        attribute :url
        attribute :accountsid
        attribute :callsid

        private

        def command_name
          COMMAND_NAME
        end

        def command_args
          [url, account_sid, call_sid]
        end
      end
    end
  end
end
