class ProductTypeSerializer < ApplicationSerializer
  attributes :name, :description, :active, :provider_type_id

  field :type_name, as: :type
  field :tag_list, :properties, :default_settings

  has_one :provider_type

  delegate :tag_list, to: :object
end
