require 'goby/service/callbacks'
require 'goby/service/logging'

module Goby
  class Service
    include Callbacks
    include Logging

    InvalidError = Class.new(StandardError)

    attr_reader :errors, :model

    class << self
      def run(*args)
        service = new(*args)
        service.run
        service
      end

      alias_method :call, :run
    end

    def initialize(context:, params:)
      @context = context
      @params = params.respond_to?(:deep_symbolize_keys) ? params.deep_symbolize_keys : params

      @errors = []
      @valid = true

      setup!
    end

    def run
      if @valid
        run_callbacks :perform do
          perform
        end
      end

      self
    rescue Goby::Exceptions::Error => e
      @valid = false
      @errors = e.errors
    rescue InvalidError
      @valid = false
    end

    alias_method :call, :run

    def invalid!(error = {}, raise_exception = false)
      @errors = error
      raise InvalidError if raise_exception

      @valid = false
    end

    def valid?
      @valid
    end

    private

    def setup!
      %i[setup_params! sanitize_params! finalize_params! assign_model! setup_model! authorize! finalize_model!].each do |setup_method|
        begin
          send setup_method
        rescue Goby::Exceptions::Error => e
          @valid = false
          @errors = e.errors
        rescue InvalidError
          @valid = false
        end

        unless @valid
          invalidated setup_method
          break
        end
      end
    end

    def setup_params!
      # Implement to alter params to your needs
    end

    def sanitize_params!
      # Implement to sanitize that the incoming params matches your schema; include Services::Sanitize as an alternative
    end

    def finalize_params!
      # Implement to alter params to your needs after they've been sanitized
    end

    def model!
      # Implement to create the model; include Services::Model as an alternative
    end

    def assign_model!
      @model = model!
    end

    def setup_model!
      # Implement to alter @model as needed
    end

    def authorize!
      # Implement to authorize the action; include Services::Policy as an alternative
    end

    def finalize_model!
      # Implement to alter @model as needed for authorized contexts
    end

    def perform
      # Implement to do operation
    end

    def invalidated(_invalid_method)
      # Implement to handle service invalidation; Receives the setup method name that caused the invalidation
    end

    attr_reader :context
    attr_accessor :params
    alias_method :current_user, :context

    def run_service(service_class, service_context: @context, service_params: @params)
      service_object = service_class.run context: service_context, params: service_params

      yield service_object if service_object.valid? && block_given?

      invalid! service_object.errors unless service_object.valid?

      service_object
    end
  end
end
