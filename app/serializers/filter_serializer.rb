class FilterSerializer < ApplicationSerializer
  attributes :exclude
  attributes :tag_list, :filterable_id, :filterable_type, sort: false
  attributes :created_at, :updated_at

  def tag_list
    object.cached_tag_list.split(/,\s?/)
  end
end
