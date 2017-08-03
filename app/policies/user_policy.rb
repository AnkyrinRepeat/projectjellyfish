class UserPolicy < ApplicationPolicy
  def search?
    true
  end

  def show?
    is_admin? || self?
  end

  def create?
    is_admin?
  end

  def create_action?
    is_admin?
  end

  def update?
    is_admin? || self?
  end

  def destroy?
    is_admin? && !self?
  end

  private

  def self?
    user.id == record.id
  end
end
