module Rayo
  module Command
    class SetVar < Adhearsion::Rayo::Command::Execute
      attribute :uuid
      attribute :name
      attribute :value

      private

      def api
        :uuid_setvar
      end

      def args
        [ uuid, name, value ]
      end
    end
  end
end
