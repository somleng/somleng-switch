class ExecuteTwiML < ApplicationWorkflow
  attr_reader :context, :twiml, :logger, :options

  def initialize(**options)
    super
    @options = options
    @context = options.fetch(:context)
    @twiml = options.fetch(:twiml)
    @logger = options.fetch(:logger)
  end

  def call
    redirect_args = catch(:redirect) do
      twiml_document.twiml.each do |verb|
        next if verb.comment?

        case verb.name
        when "Reject"
          ExecuteReject.call(TwiML::RejectVerb.parse(verb), **options)
          break
        when "Play"
          ExecutePlay.call(TwiML::PlayVerb.parse(verb), **options)
        when "Gather"
          ExecuteGather.call(TwiML::GatherVerb.parse(verb), **options)
        when "Redirect"
          ExecuteRedirect.call(TwiML::RedirectVerb.parse(verb), **options)
        when "Say"
          ExecuteSay.call(TwiML::SayVerb.parse(verb), **options)
        when "Dial"
          ExecuteDial.call(TwiML::DialVerb.parse(verb), **options)
        when "Hangup"
          break
        when "Record"
          ExecuteRecord.call(TwiML::RecordVerb.parse(verb), **options)
        when "Connect"
          ExecuteConnect.call(
            TwiML::ConnectVerb.parse(
              verb,
              allow_insecure_urls: options[:stub_call_platform_responses]
            ), **options
          )
        else
          raise(Errors::TwiMLError, "Invalid element <#{verb.name}>")
        end
      end

      false
    end

    context.redirect(*redirect_args) if redirect_args.present?
  rescue Errors::TwiMLError => e
    logger.error(e.message)
  end

  private

  def twiml_document
    @twiml_document = TwiMLDocument.new(twiml)
  end
end
