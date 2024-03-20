module Rayo
  module Component
    module TwilioStream
      class Base < Rayo::Component::Execute
        attribute :uuid
        attribute :metadata

        def domain; end
        def target_call_id; end

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
