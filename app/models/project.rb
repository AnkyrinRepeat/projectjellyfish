class Project < ApplicationRecord
  has_many :memberships, dependent: :destroy, class_name: '::Membership'
  has_many :members, class_name: '::Member'
  has_many :services, class_name: '::Service'
  has_many :filters, as: :filterable

  scope :accepts, lambda { |tags|
    tag_list = tags.split(/,\s?/)
    excluded_query = Filter.where(filterable_type: 'Project', exclude: true).where("ARRAY[?] && STRING_TO_ARRAY(cached_tag_list, ', ')", tag_list)
    required_query = Filter.where(filterable_type: 'Project', exclude: false).where("NOT ARRAY[?] && STRING_TO_ARRAY(cached_tag_list, ', ')", tag_list)
    query = Filter.joins("LEFT JOIN (#{excluded_query.to_sql}) AS excluded ON (filters.id = excluded.id)").joins("LEFT JOIN (#{required_query.to_sql}) AS required ON (filters.id = required.id)").where(filterable_type: 'Project').where('excluded.id IS NOT NULL OR required.id IS NOT NULL').select(:filterable_id).distinct

    where.not id: query.pluck(:filterable_id)
  }
end
