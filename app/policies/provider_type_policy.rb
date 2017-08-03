class ProviderTypePolicy < ApplicationPolicy
  def search?
    is_admin?
  end

  def show?
    is_admin?
  end
end
