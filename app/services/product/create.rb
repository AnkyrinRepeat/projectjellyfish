class Product < ApplicationRecord
  class Create < ApplicationService
    include Model
    include Policy
    include Sanitize
    include Validation

    model Product, :create
    policy ProductPolicy

    sanitize do
      required(:data).schema do
        required(:type, :string).filled(eql?: 'products')
        required(:attributes).schema do
          required(:product_type_id, ApplicationRecord::Types::UUID).filled(format?: ApplicationRecord::Types::UUID_REGEXP)
          required(:provider_id, ApplicationRecord::Types::UUID).filled(format?: ApplicationRecord::Types::UUID_REGEXP)
          required(:name, :string).filled(:str?)
          optional(:description, :string).value(:str?)
          optional(:tag_list, :array).each(:str?)
          required(:properties, :array).each ApplicationRecord::Types.name_value_pair
          required(:settings, :hash).filled(:hash?)
          required(:setup_price, :string).filled(format?: ApplicationRecord::Types::PRICE_REGEXP)
          required(:hourly_price, :string).filled(format?: ApplicationRecord::Types::PRICE_REGEXP)
          required(:monthly_price, :string).filled(format?: ApplicationRecord::Types::PRICE_REGEXP)
        end
      end
    end

    validation do
      configure do
        def exists?(provider_id)
          Provider.where(id: provider_id).exists?
        end
      end

      required(:provider_id).filled(:exists?)
    end

    def perform
      validate params[:data][:attributes], error_nesting: %i[data attributes] do
        schema = model.class.settings_schema :create
        nesting = %i[data attributes settings]
        validate params[:data][:attributes][:settings], schema: schema, error_nesting: nesting do |settings|
          model.assign_attributes(params[:data][:attributes].tap { |attribute| attribute.delete :settings })
          model.update settings
        end
      end
    end

    private

    def create_model!
      product_type.class.product_class.new
    end

    def product_type
      @product_type ||= ProductType.find params[:data][:attributes][:product_type_id]
    rescue
      raise Goby::Exceptions::RecordNotFound.new params[:data][:attributes][:product_type_id], '/data/attributes/product_type_id'
    end
  end
end
