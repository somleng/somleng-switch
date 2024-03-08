module Rayo
  module Command
    module AudioFork
      class Base < Adhearsion::Rayo::Command::Execute
        attribute :uuid
        attribute :metadata

        def domain; end
        def target_call_id; end

        private

        def api
          :uuid_audio_fork_twilio
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
