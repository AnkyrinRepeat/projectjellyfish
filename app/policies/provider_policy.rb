class ProviderPolicy < ApplicationPolicy
  def search?
    is_manager?
  end

  def show?
    is_manager?
  end

  def create?
    is_admin?
  end

  def update?
    is_admin?
  end

  def destroy?
    is_admin?
  end
end
