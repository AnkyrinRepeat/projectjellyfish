class Product < ApplicationRecord
  class Update < ApplicationService
    include Model
    include Policy
    include Sanitize
    include Validation

    model Product, :update
    policy ProductPolicy, :update?

    sanitize do
      required(:id, ApplicationRecord::Types::UUID).filled(format?: ApplicationRecord::Types::UUID_REGEXP)
      required(:data).schema do
        required(:type, :string).filled(eql?: 'products')
        required(:attributes).schema do
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

    def perform
      schema = model.class.settings_schema :update
      nesting = %i(data attributes settings)
      validate params[:data][:attributes][:settings], schema: schema, error_nesting: nesting do |settings|
        model.assign_attributes(params[:data][:attributes].tap { |attribute| attribute.delete :settings })
        model.update settings
      end
    end
  end
end
