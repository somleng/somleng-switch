require "adhearsion/rayo/command_node"

module Rayo
  module Command
    class UpdateCallProgress < Adhearsion::Rayo::CommandNode
      register :call_progress, :core

      attribute :flag

      def rayo_attributes
        { "flag" => flag }
      end
    end
  end
end
