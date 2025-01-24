require "adhearsion/rayo/command_node"

module Rayo
  module Command
    class UpdateCallProgress < Adhearsion::Rayo::CommandNode
      register :call_progress, :core

      attribute :status

      def rayo_attributes
        { "flag" => flag }
      end

      private

      def flag
        status == :in_progress ? 1 : 0
      end
    end
  end
end
