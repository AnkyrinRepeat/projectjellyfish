class ProjectQuestion < ActiveRecord::Base
  acts_as_paranoid

  default_scope { order('load_order') }

  has_many :project_answers

  store_accessor :options

  enum field_type: [:radio, :select_option, :text, :date]

  validates :question, presence: true
  validates :field_type, presence: true
end