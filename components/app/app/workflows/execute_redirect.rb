class ExecuteRedirect < ExecuteTwiMLVerb
  SLEEP_BETWEEN_REDIRECTS = 1

  def call
    answer!
    sleep(SLEEP_BETWEEN_REDIRECTS)
    redirect
  end

  private

  def redirect
    throw(:redirect, [ verb.content, verb.method ])
  end
end
