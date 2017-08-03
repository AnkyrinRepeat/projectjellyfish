class ServiceDetailPolicy < ApplicationPolicy
  def search?
    true
  end

  def show?
    is_manager? || ServiceDetail
      .joins(project: :memberships)
      .references(:memberships)
      .where(memberships: { user_id: context.id }, service_id: record.service_id).exists?
  end

  class Scope < Scope
    def resolve
      if context.manager? || context.admin?
        scope
      else
        scope
          .joins(project: :memberships)
          .references(:memberships)
          .where(memberships: { user_id: context.id })
      end
    end
  end
end
