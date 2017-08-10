class Filter < ApplicationRecord
  acts_as_taggable

  FILTERABLES = %w[Project].freeze

  belongs_to :filterable, polymorphic: true
end
