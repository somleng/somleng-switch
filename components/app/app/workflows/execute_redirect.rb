class ExecuteRedirect < ExecuteTwiMLVerb
  SLEEP_BETWEEN_REDIRECTS = 1

  def call
    raise(Errors::TwiMLError, "<Redirect> must contain a URL") if verb.content.blank?

    answer!
    sleep(SLEEP_BETWEEN_REDIRECTS)
    redirect
  end

  private

  def redirect
    throw(:redirect, [verb.content, verb.method])
  end
end
