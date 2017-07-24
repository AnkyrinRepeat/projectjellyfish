class Product < ApplicationRecord
  extend Settings
  include PgSearch

  acts_as_taggable
  acts_as_paranoid

  belongs_to :product_type
  belongs_to :provider
  has_many :service_requests
  has_many :services

  scope :tagged_with_any, -> (tags) { tagged_with(tags, any: true) }
  scope :not_tagged_with, -> (tags) { tagged_with(tags, exclude: true) }
  scope :project_policy, -> (project_id) { policy(Filter.where(filterable_id: project_id, filterable_type: 'Project').pluck(:exclude, :cached_tag_list)) }

  # Expect an array of [exclude::boolean, tags::text]
  # Example [[false, 'tagged,with,any'], [true, 'not,tagged,with']]
  scope :policy, lambda { |filters|
    filters.inject(all) do |query, filter|
      filter[0] ? query.not_tagged_with(filter[0]) : query.tagged_with_any(filter[1])
    end
  }

  pg_search_scope :search, against: %i(name description cached_tag_list), using: {
    tsearch: {
      dictionary: 'english',
      tsvector_column: :tsv
    }
  }

  # # Optional: Override in each product to customize service request class name
  def self.service_request_class
    to_s.sub(/Product\z/, 'ServiceRequest').constantize
  end

  # Optional: Override in each product to customize service class name
  def self.service_class
    to_s.sub(/Product\z/, 'Service').constantize
  end

  # Optional: Override in each product to define a validation schema for settings
  def self.settings_schema(_mode = :create)
    Dry::Validation.Schema(build: false)
  end

  # Optional: Override in each product
  def default_settings
    # Used to initialize the service request.
    {}
  end

  # This is here because of a bug : https://github.com/mbleigh/acts-as-taggable-on/issues/432
  def self.caching_tag_list_on?(_context)
    true
  end

  def monthly_cost
    hourly_price * 730 + monthly_price
  end

  def serializer_class_name
    'ProductSerializer'
  end
end
