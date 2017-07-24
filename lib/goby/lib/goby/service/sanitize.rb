module Goby
  class Service
    module Sanitize
      extend ActiveSupport::Concern

      private

      def sanitize_params!
        result = sanitize_schema.call(params)
        @params = result.output if result.success?

        unless result.success?
          errors = result.message_set.failures.map { |e| { path: e.path, predicate: e.predicate, text: e.text } }
          raise Goby::Exceptions::ValidationErrors, errors
        end

        result
      end

      def sanitize_schema
        self.class.sanitize_schema
      end

      class SanitizeSchema < Dry::Validation::Schema
        configure do
          config.input_processor = :sanitizer
          config.type_specs = true
        end
      end

      module ClassMethods
        attr_reader :sanitize_schema

        def sanitize(&block)
          @sanitize_schema = Dry::Validation.Schema SanitizeSchema, &block
        end
      end
    end
  end
end
