class Membership < ApplicationRecord
  ROLES = { user: 0, manager: 1, admin: 2, owner: 3 }.freeze

  belongs_to :project
  belongs_to :user

  enum role: ROLES
end
