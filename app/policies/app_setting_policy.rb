class AppSettingPolicy < ApplicationPolicy
  def show?
    true
  end

  def update?
    is_admin?
  end
end
