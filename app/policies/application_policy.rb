class ApplicationPolicy
  attr_reader :context, :record
  alias user context
  alias object record

  def initialize(context, record)
    @context = context
    @record = record
  end

  def index?
    false
  end
  alias search? index?

  def show?
    false
  end

  def create?
    false
  end

  def update?
    false
  end

  def destroy?
    false
  end

  class Scope
    attr_reader :context, :scope
    alias user context

    def initialize(context, scope)
      @context = context
      @scope = scope
    end

    def resolve
      scope
    end
  end

  private

  def manager?
    context&.active? && (context.manager? || context.admin?)
  end

  def admin?
    context&.active? && context.admin?
  end

  def owns_object?
    context&.id == object.user_id
  end
end
