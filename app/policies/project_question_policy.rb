class ProjectQuestionPolicy < ApplicationPolicy
  def search?
    true
  end

  def show?
    true
  end

  def create?
    is_manager?
  end

  def update?
    is_manager?
  end

  def destroy?
    is_manager?
  end
end
