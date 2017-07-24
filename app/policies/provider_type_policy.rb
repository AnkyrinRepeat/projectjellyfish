class ProviderTypePolicy < ApplicationPolicy
  def search?
    admin?
  end

  def show?
    admin?
  end
end
