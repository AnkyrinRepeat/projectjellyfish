class Provider < ApplicationRecord
  class Update < ApplicationService
    include Model
    include Policy
    include Sanitize
    include Validation

    model Provider, :update
    policy ProviderPolicy, :update?

    sanitize do
      required(:id, ApplicationRecord::Types::UUID).filled(format?: ApplicationRecord::Types::UUID_REGEXP)
      required(:data).schema do
        required(:type, :string).filled(eql?: 'providers')
        required(:attributes).schema do
          required(:name, :string).filled(:str?)
          optional(:description, :string).value(:str?)
          optional(:tag_list, :array).each(:str?)
          required(:credentials, :hash).filled(:hash?)
        end
      end
    end

    def perform
      schema = model.class.credentials_schema :update
      nesting = %i(data attributes credentials)
      validate params[:data][:attributes][:credentials], schema: schema, error_nesting: nesting do |credentials|
        model.assign_attributes(params[:data][:attributes].tap { |attribute| attribute.delete :credentials })
        model.update credentials

        unless model.connected?
          Provider::CheckCredentialsJob.perform_later model.id
        end
      end
    end
  end
end
