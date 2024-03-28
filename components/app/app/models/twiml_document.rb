class TwiMLDocument
  attr_reader :xml

  def initialize(xml)
    @xml = xml.strip
  end

  def twiml
    if xml_document.root.name != "Response"
      raise(Errors::TwiMLError, "The root element must be the <Response> element")
    end

    xml_document.root.children
  rescue Nokogiri::XML::SyntaxError => e
    raise Errors::TwiMLError, "Error while parsing XML: #{e.message}. XML Document: #{xml}"
  end

  private

  def xml_document
    @xml_document ||= ::Nokogiri::XML(xml) do |config|
      config.options = Nokogiri::XML::ParseOptions::NOBLANKS
    end
  end
end
