class User < ApplicationRecord
  module Password
    class Update < ApplicationService
      include Model
      include Policy
      include Sanitize
      include Validation

      model User, :find
      policy UserPolicy

      sanitize do
        required(:user_id, ApplicationRecord::Types::UUID).filled(format?: ApplicationRecord::Types::UUID_REGEXP)
        required(:data).schema do
          required(:type, :string).filled(eql?: 'user/passwords')
          required(:attributes).schema do
            required(:password, :string).filled
            required(:password_confirmation, :string).filled
          end
        end
      end

      validation do
        required(:password).filled(min_size?: User::MIN_PASSWORD_LENGTH).confirmation
      end

      def perform
        validate params[:data][:attributes], error_nesting: %i(data attributes) do |attributes|
          model.update_attributes attributes
        end
      end

      private

      def model_id
        params[:user_id]
      end
    end
  end
end
