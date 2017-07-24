class ProviderSyncPolicy < ApplicationPolicy
  def create?
    admin?
  end
end
