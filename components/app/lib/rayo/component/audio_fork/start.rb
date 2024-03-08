module Rayo
  module Component
    module AudioFork
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
          [url, accountsid, callsid]
        end
      end
    end
  end
end
