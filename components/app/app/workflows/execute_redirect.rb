class ExecuteRedirect < ExecuteTwiMLVerb
  SLEEP_BETWEEN_REDIRECTS = 1

  def call
    answer!
    sleep(SLEEP_BETWEEN_REDIRECTS)
    redirect
  end

  private

  def redirect
    throw(
      :redirect,
      {
        url: verb.content,
        http_method: verb.method
      }
    )
  end
end
