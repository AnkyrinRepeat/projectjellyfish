class ProductCategory < ApplicationRecord
  acts_as_taggable

  # This is here because of a bug : https://github.com/mbleigh/acts-as-taggable-on/issues/432
  def self.caching_tag_list_on?(_context)
    true
  end
end
