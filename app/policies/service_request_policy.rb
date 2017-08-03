class ServiceRequestPolicy < ApplicationPolicy
  def search?
    true
  end

  def show?
    is_manager? || owns_object?
  end

  def create?
    true
  end

  def update?
    is_manager? || owns_object?
  end

  def approval?
    is_manager?
  end

  def destroy?
    return false if object.approved?
    owns_object? || is_admin?
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
