class ExecutePlay < ExecuteTwiMLVerb
  def call
    answer!

    verb.loop.times.each do
      context.play_audio(verb.content)
    end
  end
end
