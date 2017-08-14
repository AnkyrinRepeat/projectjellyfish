class User < ApplicationRecord
  module Action
    class Create < ApplicationService
      include Model
      include Policy
      include Sanitize
      include Validation

      model User, :find
      policy UserPolicy, :create_action?

      sanitize do
        required(:user_id, ApplicationRecord::Types::UUID).filled(format?: ApplicationRecord::Types::UUID_REGEXP)
        required(:data).schema do
          required(:type, :string).filled(eql?: 'user/actions')
          required(:attributes).schema do
            required(:action, :string).filled(:str?)
          end
        end
      end

      validation do
        required(:action).filled(included_in?: %w(approve disable enable))

        validate valid_action?: [:action] do |event|
          model.state_events.include? event.to_sym
        end
      end

      def perform
        validate params[:data][:attributes], error_nesting: %i(data attributes) do |data|
          model.fire_events data[:action]
        end
      end

      private

      def model_id
        params[:user_id]
      end
    end
  end
end
