class ServiceRequest < ApplicationRecord
  class Update < ApplicationService
    include Model
    include Policy
    include Sanitize
    include Validation

    model ServiceRequest, :update
    policy ServiceRequestPolicy

    sanitize do
      required(:data).schema do
        required(:id, ApplicationRecord::Types::UUID).filled(format?: ApplicationRecord::Types::UUID_REGEXP)
        required(:type, :string).filled(eql?: 'service_requests')
        required(:attributes).schema do
          required(:service_name, :string).filled(:str?)
          optional(:request_message, :string).maybe(:str?)
          required(:settings, :hash).maybe(:hash?)
        end
      end
    end

    def perform
      data = params[:data][:attributes][:settings]
      schema = model.class.settings_schema :update
      nesting = %i(data attributes settings)
      validate data, schema: schema, error_nesting: nesting do |settings|
        model.assign_attributes(params[:data][:attributes].tap { |attribute| attribute.delete :settings })
        model.assign_attributes settings
        model.configure!
      end
    end
  end
end
