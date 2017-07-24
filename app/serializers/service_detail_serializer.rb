class ServiceDetailSerializer < ApplicationSerializer
  attributes :service_id, :provider_id, :product_id, :project_id, :service_order_id, :requester_id, sort: false
  attributes :created_at, :updated_at, filter: false

  attributes :service_type, :service_name, :product_type, :product_name, :product_type_name
  attributes :provider_type, :provider_name, :project_name
  attributes :state
  attributes :setup_price, :hourly_price, :monthly_price

  fields :status_message, :tag_list, :settings, :details, :actions
  fields :last_changed_at, :last_checked_at
  field :monthly_cost

  has_one :requester
  has_one :service_order
  has_one :service_request
  has_one :provider
  has_one :product

  def _id
    object.service_id
  end

  def product_type
    object.product_type.underscore
  end

  def provider_type
    object.provider_type.underscore
  end

  def service_type
    object.service_type.underscore
  end

  def tag_list
    object.tag_list.split(/,\s?/)
  end

  def actions
    object.actions.split(/,\s?/)
  end
end
