class ProviderSyncPolicy < ApplicationPolicy
  def create?
    is_admin?
  end
end
