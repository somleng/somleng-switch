class ExecuteTwiML < ApplicationWorkflow
  attr_reader :context, :twiml, :logger, :options

  def initialize(**options)
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
          ExecuteReject.call(TwiML::RejectVerb.new(verb), **options)
          break
        when "Play"
          ExecutePlay.call(TwiML::PlayVerb.new(verb), **options)
        when "Gather"
          ExecuteGather.call(TwiML::GatherVerb.new(verb), **options)
        when "Redirect"
          ExecuteRedirect.call(TwiML::RedirectVerb.new(verb), **options)
        when "Say"
          ExecuteSay.call(TwiML::SayVerb.new(verb), **options)
        when "Dial"
          ExecuteDial.call(TwiML::DialVerb.new(verb), **options)
        when "Hangup"
          break
        when "Record"
          ExecuteRecord.call(TwiML::RecordVerb.new(verb), **options)
        when "Connect"
          ExecuteConnect.call(TwiML::ConnectVerb.new(verb), **options)
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
