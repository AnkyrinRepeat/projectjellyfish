class MemberPolicy < ApplicationPolicy
  def search?
    true
  end

  def show?
    owns_object? || is_manager? || Member
      .joins(project: :memberships)
      .references(:memberships)
      .where(memberships: { user_id: context.id, role: [Membership.roles[:admin], Membership.roles[:owner]] }, id: record.id).exists?
  end

  class Scope < Scope
    def resolve
      if context.manager? || context.admin?
        scope
      else
        # Limit results to projects the user is a member of as either an admin or an owner
        scope
          .joins(project: :memberships)
          .references(project: :memberships)
          .where(memberships: { user_id: context.id, role: [Membership.roles[:admin], Membership.roles[:owner]] })
      end
    end
  end
end
