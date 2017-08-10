class Provider < ApplicationRecord
  class Create < ApplicationService
    include Model
    include Policy
    include Sanitize
    include Validation

    model Provider, :create
    policy ProviderPolicy

    sanitize do
      required(:data).schema do
        required(:type, :string).filled(eql?: 'providers')
        required(:attributes).schema do
          required(:provider_type_id, ApplicationRecord::Types::UUID).filled(format?: ApplicationRecord::Types::UUID_REGEXP)
          required(:name, :string).filled(:str?)
          optional(:description, :string).value(:str?)
          optional(:tag_list, :array).each(:str?)
          required(:credentials, :hash).filled(:hash?)
        end
      end
    end

    def perform
      schema = model.class.credentials_schema :create
      nesting = %i[data attributes credentials]
      validate params[:data][:attributes][:credentials], schema: schema, error_nesting: nesting do |credentials|
        model.assign_attributes(params[:data][:attributes].tap { |attribute| attribute.delete :credentials })
        model.credentials_validated_at = DateTime.current
        model.last_synced_at = DateTime.current
        model.update credentials

        # Schedule a syncing of this providers data
        ProviderData::SyncJob.set(wait: ApplicationJob::WAIT).perform_later model.id, model.last_synced_at.to_s
      end
    end

    private

    def create_model!
      provider_type.class.provider_class.new
    end

    def provider_type
      @provider_type ||= ProviderType.find params[:data][:attributes][:provider_type_id]
    rescue
      raise Goby::Exceptions::RecordNotFound.new params[:data][:attributes][:provider_type_id], '/data/attributes/provider_type_id'
    end
  end
end
