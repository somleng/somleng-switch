class TwiMLParser
  attr_reader :content

  def initialize(content)
    @content = content
  end

  def parse
    doc = ::Nokogiri::XML(content) do |config|
      config.options = Nokogiri::XML::ParseOptions::NOBLANKS
    end

    raise(Errors::TwiMLError, "The root element must be the '<Response>' element") if doc.root.name != "Response"

    doc.root.children
  rescue Nokogiri::XML::SyntaxError => e
    raise(Errors::TwiMLError, "Error while parsing XML: #{e.message}. XML Document: #{xml}")
  end
end
