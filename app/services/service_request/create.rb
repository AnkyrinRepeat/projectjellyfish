class ServiceRequest < ApplicationRecord
  class Create < ApplicationService
    include Model
    include Policy
    include Sanitize
    include Validation

    model ServiceRequest, :create
    policy ServiceRequestPolicy

    sanitize do
      required(:data).schema do
        required(:type, :string).filled(eql?: 'service_requests')
        required(:attributes).schema do
          required(:product_id, ApplicationRecord::Types::UUID).filled
          required(:project_id, ApplicationRecord::Types::UUID).filled
        end
      end
    end

    validation do
      required(:product_id).filled(format?: ApplicationRecord::Types::UUID_REGEXP)
      required(:project_id).filled(format?: ApplicationRecord::Types::UUID_REGEXP)

      validate exists?: [:product_id] do |product_id|
        Product.where(id: product_id).exists?
      end

      validate project_exists?: [:project_id] do |project_id|
        if context.manager? || context.admin?
          Project.where(id: project_id).exists?
        else
          Membership.where(user_id: model.user_id, project_id: project_id).exists?
        end
      end

      validate accepted?: %i(product_id project_id) do |product_id, project_id|
        Project.accepts(Product.find(product_id).cached_tag_list).where(id: project_id).exists?
      end
    end

    def perform
      validate params[:data][:attributes], error_nesting: %i(data attributes) do |attributes|
        model.settings = product.default_settings
        model.update attributes
      end
    end

    private

    def setup_model!
      model.user_id = context.id
    end

    def create_model!
      product.class.service_request_class.new
    end

    def product
      @product ||= Product.find params[:data][:attributes][:product_id]
    rescue
      raise Goby::Exceptions::RecordNotFound.new params[:data][:attributes][:product_id], '/data/attributes/product_id'
    end
  end
end
