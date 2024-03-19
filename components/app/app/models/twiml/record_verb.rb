require_relative "twiml_verb"

module TwiML
  class RecordVerb < TwiMLVerb
    def action
      attributes["action"]
    end

    def method
      attributes["method"]
    end

    def status_callback_url
      attributes["recordingStatusCallback"]
    end

    def status_callback_method
      attributes["recordingStatusCallbackMethod"]
    end

    def max_length
      attributes.fetch("maxLength", 3600).to_i
    end

    def timeout
      attributes.fetch("timeout", 5).to_i
    end

    def play_beep
      attributes["playBeep"] != "false"
    end

    def finish_on_key
      attributes.fetch("finishOnKey", "1234567890*#")
    end

    private

    def attributes
      super(verb)
    end
  end
end
