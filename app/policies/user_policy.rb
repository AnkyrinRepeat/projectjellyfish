class UserPolicy < ApplicationPolicy
  def search?
    true
  end

  def show?
    admin? || self?
  end

  def create?
    admin?
  end

  def create_action?
    admin?
  end

  def update?
    admin? || self?
  end

  def destroy?
    admin? && !self?
  end

  private

  def self?
    user.id == record.id
  end
end
