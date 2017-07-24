class ProviderTypeSerializer < ApplicationSerializer
  attribute :type_name, as: :type
  attributes :name, :description, :active, :tag_list

  has_many :providers
  has_many :product_types

  delegate :tag_list, to: :object
end
