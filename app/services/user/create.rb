class User < ApplicationRecord
  class Create < ApplicationService
    include Model
    include Sanitize
    include Validation

    model User, :create

    sanitize do
      required(:data).schema do
        required(:type, :string).filled(eql?: 'users')
        required(:attributes).schema do
          required(:name, :string).filled
          required(:email, User::Types::EMAIL).filled(format?: User::Types::EMAIL_REGEXP)
          required(:role, :string).filled
          required(:state, :string).filled
          required(:password, :string).filled
          required(:password_confirmation, :string).filled
        end
      end
    end

    validation do
      configure do
        predicates(User::Predicates)
      end

      required(:data).schema do
        required(:attributes).schema do
          required(:name).filled
          required(:email).filled(:str?, :unique_email?)
          required(:role).filled(included_in?: User.roles.keys)
          required(:state).filled(included_in?: %w(pending active disabled))
          required(:password).filled(min_size?: User::MIN_PASSWORD_LENGTH).confirmation
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
