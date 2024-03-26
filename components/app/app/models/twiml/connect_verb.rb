require_relative "twiml_node"

module TwiML
  class ConnectVerb < TwiMLNode
    class StreamNoun < TwiMLNode
      class Parser < TwiML::NodeParser
        VALID_NOUNS = [ "Parameter" ].freeze

        attr_reader :allow_insecure_urls

        def initialize(**options)
          super()
          @allow_insecure_urls = options.fetch(:allow_insecure_urls) do
            CallPlatform.configuration.stub_responses
          end
        end

        def parse(node)
          node_options = super
          node_options[:url] = node_options.dig(:attributes, "url")
          node_options[:parameters] = build_parameters
          node_options
        end

        private

        def valid?
          validate_attributes && validate_nested_nouns
          super
        end

        def validate_attributes
          url_scheme = parse_url_scheme(attributes["url"])
          return true if url_scheme == "wss"
          return true if allow_insecure_urls && url_scheme == "ws"

          errors.add("<Stream> must contain a valid wss 'url' attribute")
          false
        end

        def validate_nested_nouns
          return true if nested_nodes.all? { |nested_node| VALID_NOUNS.include?(nested_node.name) }

          errors.add("<Stream> must only contain <Parameter> nouns")
          false
        end

        def parse_url_scheme(url)
          URI(url.to_s).scheme
        end

        def build_parameters
          nested_nodes.each_with_object({}) do |nested_node, result|
            parameter_noun = ParameterNoun.parse(nested_node)
            result[parameter_noun.name] = parameter_noun.value
          end
        end

        def parse_url_scheme(url)
          URI(url.to_s).scheme
        end
      end

      class << self
        def parse(node, **options)
          super(node, parser: Parser.new(**options))
        end
      end

      attr_reader :url, :parameters

      def initialize(url:, parameters:, **options)
        super(**options)
        @url = url
        @parameters = parameters
      end
    end

    class ParameterNoun < TwiMLNode
      class Parser < TwiML::NodeParser
        def parse(node)
          node_options = super
          node_options[:name] = node_options.dig(:attributes, "name")
          node_options[:value] = node_options.dig(:attributes, "value")
          node_options
        end

        private

        def valid?
          validate_attributes
          super
        end

        def validate_attributes
          return if noun.attributes["name"].present? && noun.attributes["value"].present?

          errors.add("<Parameter> must have a 'name' and 'value' attribute")
        end

        def noun
          @noun ||= TwiMLNode.parse(node)
        end
      end

      class << self
        def parse(node)
          super(node, parser: Parser.new)
        end
      end

      attr_reader :name, :value

      def initialize(name:, value:, **options)
        super(options)
        @name = name
        @value = value
      end
    end

    class Parser < TwiML::NodeParser
      VALID_NOUNS = [ "Stream" ].freeze

      def parse(node)
        super.merge(stream_noun:)
      end

      private

      def valid?
        validate_nested_nouns

        super
      end

      def validate_nested_nouns
        return if nested_nodes.one? && VALID_NOUNS.include?(nested_nodes.first.name)

        valid_nouns = VALID_NOUNS.map { |noun| "<#{noun}>" }.join(", ")
        errors.add("<Connect> must contain exactly one of the following nouns: #{valid_nouns}")
      end

      def stream_noun
        @stream_noun ||= StreamNoun.parse(nested_nodes.first)
      end
    end

    class << self
      def parse(node, **options)
        super(node, parser: Parser.new(**options))
      end
    end

    attr_reader :stream_noun

    def initialize(stream_noun:, **options)
      super(**options)
      @stream_noun = stream_noun
    end
  end
end
