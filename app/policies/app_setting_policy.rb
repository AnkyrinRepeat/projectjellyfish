class AppSettingPolicy < ApplicationPolicy
  def show?
    true
  end

  def update?
    admin?
  end
end
