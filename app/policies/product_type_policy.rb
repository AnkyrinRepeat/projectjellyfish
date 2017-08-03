class ProductTypePolicy < ApplicationPolicy
  def search?
    is_manager?
  end

  def show?
    is_manager?
  end

  def create?
    is_manager?
  end

  def update?
    is_manager?
  end

  def destroy?
    is_manager?
  end
end
