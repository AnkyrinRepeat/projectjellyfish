class User < ApplicationRecord
  class Update < ApplicationService
    include Model
    include Policy
    include Sanitize
    include Validation

    model User, :update
    policy UserPolicy

    sanitize do
      required(:id, ApplicationRecord::Types::UUID).filled(format?: ApplicationRecord::Types::UUID_REGEXP)
      required(:data).schema do
        required(:type, :string).filled(eql?: 'users')
        required(:attributes).schema do
          required(:name, :string).filled
          required(:email, User::Types::EMAIL).filled(format?: User::Types::EMAIL_REGEXP)
          required(:role, :string).filled
        end
      end
    end

    validation do
      configure do
        predicates(User::Predicates)
      end

      required(:data).schema do
        required(:attributes).schema do
          required(:name).filled(:str?)
          required(:email).filled(:str?)
          required(:role).filled(included_in?: User.roles.keys)
          validate no_role_change?: %i(role) do |role|
            model.id != context.id || role == context.role
          end

          validate unique_email?: %i(email) do |email|
            User.where(email: email).where.not(id: model.id).none?
          end
        end
      end
    end

    def perform
      validate do |data|
        model.update_attributes data[:data][:attributes]
      end
    end
  end
end
