#!/usr/bin/env ruby

require "test/unit"
require "pathname"
require "open3"

class ExporterTest < Test::Unit::TestCase
  def test_export
    script = File.expand_path(File.join(__dir__, "../../bin/export_tts_voices"))
    stdout, status = Open3.capture2({ "TTS_VOICES" => "basic" }, script)

    assert(status.success?)
    assert(stdout.include?('<voice name="Basic.Kal" language="en-US" gender="Male" prefix="tts://flite|kal|"/>'))
    assert(stdout.include?('<voice name="Basic.Slt" language="en-US" gender="Female" prefix="tts://flite|slt|"/>'))
  end
end
