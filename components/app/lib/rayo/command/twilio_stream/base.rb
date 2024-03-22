module Rayo
  module Command
    module TwilioStream
      class Base < Adhearsion::Rayo::Command::Execute
        attribute :uuid
        attribute :metadata

        def domain; end
        def target_call_id; end

        private

        def api
          :uuid_twilio_stream
        end

        def args
          [uuid, command_name, *command_args, Base64.urlsafe_encode64(metadata)].compact
        end

        def command_args
          []
        end
      end
    end
  end
end
