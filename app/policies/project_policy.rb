class ProjectPolicy < ApplicationPolicy
  def search?
    true
  end

  def show?
    is_manager? || Membership.where(user_id: context.id, project_id: record.id).exists?
  end

  def update?
    is_manager? || Membership.where(user_id: context.id, project_id: record.id).exists?
  end

  class Scope < Scope
    def resolve
      if context.manager? || context.admin?
        scope
      else
        scope.joins(:memberships).references(:memberships).where(memberships: { user_id: context.id })
      end
    end
  end
end
