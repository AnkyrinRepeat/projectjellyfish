class CredentialValidation
  class Create < ApplicationService
    include Sanitize
    include Validation

    sanitize do
      required(:data).schema do
        optional(:id, ApplicationRecord::Types::UUID).maybe(format?: ApplicationRecord::Types::UUID_REGEXP)
        required(:type, :string).filled(eql?: 'providers')
        required(:attributes).schema do
          required(:provider_type_id, ApplicationRecord::Types::UUID).filled(format?: ApplicationRecord::Types::UUID_REGEXP)
          required(:credentials, :hash).filled(:hash?)
        end
      end
    end

    def perform
      schema = model.provider.class.credentials_schema :update
      nesting = %i(data attributes credentials)
      validate params[:data][:attributes][:credentials], schema: schema, error_nesting: nesting do |credentials|
        model.provider.assign_attributes credentials
        begin
          model.provider.valid_credentials?
          model.valid = true
          model.message = 'OK'
        rescue => error
          model.valid = false
          model.message = error.message
        end
      end
    end

    def model!
      model = CredentialValidation.new
      model.provider = if params[:data][:id]
                         Provider.find params[:data][:id]
                       else
                         provider_type.class.provider_class.new
                       end

      model
    end

    def provider_type
      @provider_type ||= ProviderType.find params[:data][:attributes][:provider_type_id]
    rescue
      raise Goby::Exceptions::RecordNotFound.new params[:data][:attributes][:provider_type_id], '/data/attributes/provider_type_id'
    end
  end
end
