module Rayo
  module Command
    module AudioFork
      class Base < Adhearsion::Rayo::Command::Execute
        attribute :uuid
        attribute :metadata

        private

        def api
          :uuid_audio_fork
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
