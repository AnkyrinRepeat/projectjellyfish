class ProviderPolicy < ApplicationPolicy
  def search?
    manager?
  end

  def show?
    manager?
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end
end
