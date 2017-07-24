class ProductCategoryPolicy < ApplicationPolicy
  def search?
    true
  end

  def show?
    true
  end

  def create?
    manager?
  end

  def update?
    manager?
  end

  def destroy?
    manager?
  end
end
