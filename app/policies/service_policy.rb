class ServicePolicy < ApplicationPolicy
  def search?
    true
  end

  def show?
    manager? || Service
      .joins(service_request: { project: :memberships })
      .references(:memberships)
      .where(memberships: { user_id: context.id }, id: record.id).exists?
  end

  def update?
    manager? || Service
      .joins(service_request: { project: :memberships })
      .references(:memberships)
      .where(memberships: { user_id: context.id }, id: record.id).exists?
  end

  class Scope < Scope
    def resolve
      if context.manager? || context.admin?
        scope
      else
        scope
          .joins(service_request: { project: :memberships })
          .references(:memberships)
          .where(memberships: { user_id: context.id })
      end
    end
  end
end
