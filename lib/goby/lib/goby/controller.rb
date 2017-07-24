module Goby
  module Controller
    extend ActiveSupport::Concern

    included do
      rescue_from Goby::Service::NotAuthorizedError, with: :unauthorized_access!
    end

    def index
      handle service_class::Search do |success|
        render_results success.model, collection: true
      end
    end

    def show
      handle service_class::Show do |success|
        render_results success.model
      end
    end

    def create
      handle service_class::Create do |success|
        render_results success.model, status: :created
      end
    end

    def update
      handle service_class::Update do |success|
        render_results success.model
      end
    end

    def destroy
      handle service_class::Destroy do |_success|
        head :no_content
      end
    end

    protected

    def run(service_class, context: context_for_service, params: params_for_service)
      service_object = service_class.run context: context, params: params

      yield service_object if service_object.valid? && block_given?

      service_object
    end

    def handle(service_class)
      if request_parser.errors.empty?
        service_params = params_for_service.to_unsafe_hash.merge(request_parser.params)
        failure = run service_class, params: service_params do |success|
          yield success if block_given?
          return
        end

        render_errors failure.errors
      else
        render_errors request_parser.errors
      end
    end

    def service_class
      self.class.service_class
    end

    def resource_class
      self.class.resource_class
    end

    def request_parser
      @request ||= Goby::RequestParser.new(resource_class, context_for_service, params)
    end

    # Override in the controller to replace or append
    def base_url
      @base_url ||= request.protocol + request.host_with_port
    end

    def params_for_service
      action_params_method = "#{action_name}_params".to_sym
      controller_params_method = "#{controller_name}_params".to_sym

      service_params = if respond_to? action_params_method, true
                         send action_params_method
                       elsif respond_to? controller_params_method, true
                         send controller_params_method
                       else
                         params
                       end

      service_params = ActionController::Parameters.new(service_params) unless service_params.is_a? ActionController::Parameters

      service_params
    end

    def context_for_service
      send self.class.service_context_method || :current_user
    end

    def render_errors(errors)
      status = errors.first.status

      render status: status, json: { errors: errors }
    end

    def render_results(results, options = {})
      status = options.delete(:status) || 200

      render status: status, json: Goby::Serializer.serialize(
        results,
        {
          context: context_for_service,
          fields: request_parser.fields,
          include: request_parser.included_resources,
          base_url: base_url
        }.merge(ResponseExtras.new(results, action: params[:action],
                                            request: request_parser,
                                            base_url: request.protocol + request.host_with_port + request.path).extras.merge(options))
      )
    rescue Goby::Exceptions::Error => e
      render_errors e.errors
    end

    module ClassMethods
      attr_reader :service_context_method

      def service_context(context_method)
        @service_context_method = context_method
      end

      def service_class(model_class = nil)
        @service_class = model_class unless model_class.nil?

        @service_class ||= controller_name.classify.constantize
      end

      def resource_class(model_class = nil)
        @resource_class = model_class unless model_class.nil?

        @resource_class ||= controller_name.classify.constantize
      end
    end
  end
end
