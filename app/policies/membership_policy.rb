class MembershipPolicy < ApplicationPolicy
  def search?
    true
  end

  def show?
    owns_object? || manager? || Member
      .joins(project: :memberships)
      .where(memberships: { user_id: context.id, role: [Membership.roles[:admin], Membership.roles[:owner]] }, id: record.id).exists?
  end

  def create?
    # Use `setup_model!` to assign the `project_id` to the model before it's authorized
    manager? || Membership.where(user_id: context.id, project_id: record.project_id, role: [Membership.roles[:admin], Membership.roles[:owner]]).exists?
  end

  def update?
    manager? || Member
      .joins(project: :memberships)
      .where(memberships: { user_id: context.id, role: [Membership.roles[:admin], Membership.roles[:owner]] }, id: record.id).exists?
  end

  def destroy?
    manager? || Member
      .joins(project: :memberships)
      .where(memberships: { user_id: context.id, role: [Membership.roles[:admin], Membership.roles[:owner]] }, id: record.id).exists?
  end

  class Scope < Scope
    def resolve
      if context.manager? || context.admin?
        scope
      else
        scope
          .joins(project: :memberships)
          .where(memberships_projects: { user_id: context.id, role: [Membership.roles[:admin], Membership.roles[:owner]] })
      end
    end
  end
end
