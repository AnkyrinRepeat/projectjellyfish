class ProviderDataPolicy < ApplicationPolicy
  def search?
    true
  end

  def show?
    true
  end

  def sync?
    admin?
  end
end
