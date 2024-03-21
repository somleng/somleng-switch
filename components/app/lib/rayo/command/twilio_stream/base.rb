module Rayo
  module Command
    module TwilioStream
      class Base < Adhearsion::Rayo::Command::Execute
        attribute :uuid
        attribute :metadata

        private

        def api
          :uuid_twilio_stream
        end

        def args
          [uuid, command_name, *command_args, metadata].compact
        end

        def command_args
          []
        end
      end
    end
  end
end
