class ProviderData < ApplicationRecord
  belongs_to :provider

  scope :like, ->(query) { where('provider_data.name ILIKE :query', query: "#{query.downcase.gsub(/%|_/, '\\\\\0')}%") }
end
