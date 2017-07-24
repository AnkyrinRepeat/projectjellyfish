class FilterPolicy < ApplicationPolicy
  def search?
    true
  end

  def show?
    true
  end

  def create?
    # TODO: Enforce permission checks
    true
  end

  def update?
    # TODO: Enforce permission checks
    true
  end

  def destroy?
    # TODO: Enforce permission checks
    true
  end

  class Scope
    # TODO: Apply scope
    def resolve
      scope
    end
  end
end
