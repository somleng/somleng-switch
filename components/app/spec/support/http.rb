HTTP.default_options = HTTP::Options.new(
  features: {
    logging: {
      logger: Logger.new(IO::NULL)
    }
  }
)
