require "adhearsion/rayo/component/component_node"

module Rayo
  module Component
    class Execute < Adhearsion::Rayo::Component::ComponentNode
      register :exec, :core

      attribute :api
      attribute :args

      def args=(value)
        value.is_a?(String) ? super(value.split(/\s+/)) : super
      end

      def rayo_attributes
        { api:, args: args.join(" ") }
      end
    end
  end
end
