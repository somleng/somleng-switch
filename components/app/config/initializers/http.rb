# To enable logging for all request & response headers and bodies
HTTP.default_options = HTTP::Options.new(
  features: {
    logging: {
      logger: Logger.new(STDOUT)
    }
  }
)
