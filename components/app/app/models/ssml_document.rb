class SSMLDocument
  attr_reader :content, :tts_voice

  def initialize(content:, tts_voice:)
    @content = content
    @tts_voice = tts_voice
  end

  def to_ssml
    build_ssml_doc(content:, tts_voice:)
  end

  private

  def build_ssml_doc(content:, tts_voice:)
    ssml = RubySpeech::SSML.draw do
      voice(name: tts_voice.identifier, language: tts_voice.language) do
        # mod ssml doesn't support non-ascii characters
        # https://github.com/signalwire/freeswitch/issues/1348
        string("#{content}.")
      end
    end
    ssml.document.encoding = "UTF-8"
    ssml
  end
end
