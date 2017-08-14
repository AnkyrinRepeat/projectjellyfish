class Project < ApplicationRecord
  class Update < ApplicationService
    include Model
    include Policy
    include Sanitize
    include Validation

    model Project, :update
    policy ProjectPolicy, :update?

    sanitize do
      required(:id, ApplicationRecord::Types::UUID).filled(format?: ApplicationRecord::Types::UUID_REGEXP)
      required(:data).schema do
        required(:type, :string).filled(eql?: 'projects')
        required(:attributes).schema do
          required(:name, :string).filled(:str?)
          optional(:description, :string).value(:str?)
          optional(:budget, :string).maybe(format?: ApplicationRecord::Types::BUDGET_REGEXP)
        end
      end
    end

    validation do
      optional(:budget).maybe(format?: ApplicationRecord::Types::BUDGET_REGEXP)

      validate budget: %i(budget) do |_budget|
        Membership.where(user_id: context.id, project_id: model.id, role: %i(admin owner)).exists?
      end
    end

    def perform
      validate params[:data][:attributes], error_nesting: %i(data attributes) do |data|
        model.update data
      end
    end
  end
end
