module Adhearsion
  module Twilio
    class Plugin < Adhearsion::Plugin
      # Actions to perform when the plugin is loaded
      #
      init :twilio do
        logger.warn "Twilio has been loaded"
      end

      # Basic configuration for the plugin
      #
      config :twilio do
        account_sid(
          nil,
          :desc => "The default Account Sid to be used in voice_url and status_callback_url requests"
        )

        auth_token(
          nil,
          :desc => "The Auth Token to be used to generate the request signature"
        )

        voice_request_url(
          nil,
          :desc => "Retrieve and execute the TwiML at this URL when a phone call is received"
        )

        voice_request_method(
          nil,
          :desc => "Retrieve and execute the TwiML using this http method"
        )

        status_callback_url(
          nil,
          :desc => "Make a request to this URL when a call to this phone number is completed."
        )

        status_callback_method(
          nil,
          :desc => "Make a request to the status_callback_url using this method when a call to this phone number is completed."
        )

        default_male_voice(
          nil,
          :desc => "The default voice to use for a male speaker (see 'config.punchblock.default_voice' for allowed values)"
        )

        default_female_voice(
          nil,
          :desc => "The default voice to use for a female speaker (see 'config.punchblock.default_voice' for allowed values)"
        )

        rest_api_enabled(
          nil,
          :desc => "Set to 1 to if you have a Twilio REST API enabled"
        )

        rest_api_phone_calls_url(
          nil,
          :desc => "The Twilio REST API's endpoint for creating new phone calls"
        )

        rest_api_phone_call_events_url(
          nil,
          :desc => "The Twilio REST API's endpoint for creating new phone call events"
        )
      end

      # Defining a Rake task is easy
      # The following can be invoked with:
      #   rake adhearsion:twilio:info
      #
      tasks do
        namespace :adhearsion do
          namespace :twilio do
            desc "Prints the adhearsion-twilio information"
            task :info do
              STDOUT.puts "adhearsion-twilio plugin v. #{VERSION}"
            end
          end
        end
      end
    end
  end
end
