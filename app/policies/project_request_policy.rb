class ProjectRequestPolicy < ApplicationPolicy
  def search?
    true
  end

  def show?
    owns_object? || manager?
  end

  def create?
    true
  end

  def update?
    owns_object? || manager?
  end

  def approval?
    manager?
  end

  def destroy?
    manager?
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
