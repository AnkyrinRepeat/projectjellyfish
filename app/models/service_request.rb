class ServiceRequest < ApplicationRecord
  extend Settings

  acts_as_paranoid

  belongs_to :user
  belongs_to :processor, class_name: '::User'
  belongs_to :product
  has_one :provider, through: :product
  belongs_to :project
  belongs_to :service_order
  has_one :service

  state_machine :state, initial: :pending do
    event :configure do
      transition %i(pending configured) => :configured
    end

    event :order do
      # Auto approve is on and the provider is connected
      transition configured: :approved, if: ->(request) { request.auto_approval? && request.provider_connected? }
      # Auto approve is on but the provider is not connected
      transition configured: :delayed, if: ->(request) { request.auto_approval? }
      # Leave the request to be approved or denied
      transition configured: :ordered
    end

    event :approve do
      # Approve the request if the provider is connected
      transition %i(delayed ordered) => :approved, if: ->(request) { request.provider_connected? }
      # The provider is not connected
      transition ordered: :delayed
    end

    after_transition to: :approved do |request, _transition|
      ServiceRequest::BuildServiceJob.set(wait: ApplicationJob::WAIT).perform_later request.id
    end

    event :deny do
      transition ordered: :denied
    end
  end

  # Optional: Override in each service request to customize service class name
  def self.service_class
    to_s.sub(/Request\z/, '').constantize
  end

  # Optional: Override in each service request to define a validation schema for settings
  def self.settings_schema(_mode = :create)
    Dry::Validation.Schema(build: false)
  end

  # TODO: Remove this after removing the price columns from service_requests; use the products.*_price columns
  def monthly_cost
    (hourly_price || 0) * 730 + (monthly_price || 0)
  end

  def auto_approval?
    AppSetting.current.auto_approve_services
  end

  def provider_connected?
    product.provider.connected?
  end

  # All ServiceRequests use the same serializer
  def serializer_class_name
    'ServiceRequestSerializer'
  end
end
