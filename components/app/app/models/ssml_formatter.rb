class SSMLFormatter < Adhearsion::CallController::Output::Formatter
  def ssml_for_collection(*)
    result = super
    result.document.encoding = "UTF-8"
    result
  end
end
