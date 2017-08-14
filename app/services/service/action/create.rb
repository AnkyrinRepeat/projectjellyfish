class Service < ApplicationRecord
  module Action
    class Create < ApplicationService
      include Model
      include Sanitize
      include Validation

      model Service, :find

      sanitize do
        required(:service_id, ApplicationRecord::Types::UUID).filled(format?: ApplicationRecord::Types::UUID_REGEXP)
        required(:data).schema do
          required(:id, ApplicationRecord::Types::UUID).filled(format?: ApplicationRecord::Types::UUID_REGEXP)
          required(:type, :string).filled(eql?: 'service/actions')
          required(:attributes).schema do
            required(:action, :string).filled(:str?)
          end
        end
      end

      validation do
        required(:action).filled(:str?)

        validate valid_action?: [:action] do |action|
          model.state_events.include? action.to_sym
        end
      end

      def perform
        validate params[:data][:attributes], error_nesting: %i(data attributes) do |data|
          Service::State::ChangeJob.perform_later model.id, data[:action]
        end
      end

      def model_id
        params[:service_id]
      end
    end
  end
end
