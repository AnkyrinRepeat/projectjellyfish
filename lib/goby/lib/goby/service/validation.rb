module Goby
  class Service
    module Validation
      extend ActiveSupport::Concern

      private

      def validate(params_to_validate = params, schema: validation_schema, error_nesting: [], raise: true)
        result = schema.new(context: context || {}, model: model).call(params_to_validate)

        if result.success?
          yield result.output if block_given?
        end

        unless result.success? || raise == false
          errors = result.message_set.failures.map { |e| { path: error_nesting.concat(e.path), predicate: e.predicate, text: e.text } }
          raise Goby::Exceptions::ValidationErrors, errors
        end

        result
      end

      def validation_schema
        self.class.validation_schema
      end

      class ValidationSchema < Dry::Validation::Schema
        configure do
          option :context
          option :model

          config.type_specs = true
        end
      end

      module ClassMethods
        attr_reader :validation_schema

        def validation(&block)
          @validation_schema = Dry::Validation.Schema(ValidationSchema, build: false, &block)
        end
      end
    end
  end
end
