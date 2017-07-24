class ProductCategorySerializer < ApplicationSerializer
  type :product_categories

  attributes :name, :description, :tag_list
  attributes :created_at, :updated_at

  def tag_list
    object.cached_tag_list.split(/,\s?/)
  end
end
