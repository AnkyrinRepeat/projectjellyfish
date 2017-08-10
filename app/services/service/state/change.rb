class Service < ApplicationRecord
  module State
    class Change < ApplicationService
      include Model
      include Sanitize
      include Validation

      model Service, :find

      sanitize do
        required(:action, :string).filled(:str?)
      end

      validation do
        required(:action, :string).filled(:str?)

        validate valid_action?: [:action] do |event|
          model.state_events.include? event.to_sym
        end
      end

      def perform
        validate do
          if model.fire_events params[:action]
            model.update last_checked_at: DateTime.current
          else
            invalid! unless model.error?
          end
        end
      rescue StateMachines::InvalidEvent => error
        # Handle invalid state changes as unrecoverable changes
        model.status_message = error.message
        model.save
      end
    end
  end
end
