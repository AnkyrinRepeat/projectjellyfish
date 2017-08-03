class ServiceOrderPolicy < ApplicationPolicy
  def search?
    true
  end

  def show?
    owns_object? || is_manager?
  end

  def create?
    true
  end

  def update?
    owns_object? || is_manager?
  end

  def destroy?
    is_admin?
  end

  class Scope < Scope
    def resolve
      if context.manager? || context.admin?
        scope
      else
        scope.where(user_id: context.id)
      end
    end
  end
end
