class ServiceRequest < ApplicationRecord
  class Approval
    class Create < ApplicationService
      include Model
      include Policy
      include Sanitize

      model ServiceRequest, :update
      policy ServiceRequestPolicy, :approval?

      sanitize do
        required(:service_request_id, ApplicationRecord::Types::UUID).filled(format?: ApplicationRecord::Types::UUID_REGEXP)
        required(:data).schema do
          required(:type, :string).filled(eql?: 'service_request/approvals')
          required(:attributes).schema do
            required(:approval, :string).filled(included_in?: %w(approve deny))
            optional(:reason_message, :string).maybe(:str?)
          end
        end
      end

      def perform
        if model.fire_events params[:data][:attributes][:approval]
          model.processor_id = processor.id
          model.processed_message = processed_message
          model.save

          ServiceOrder::RecountJob.perform_later(model.service_order_id)

          if model.approved?
            ServiceRequestMailer.approval(model).deliver_later
          elsif model.denied?
            ServiceRequestMailer.denial(model).deliver_later
          end
        end
      end

      private

      def model_id
        params[:service_request_id]
      end

      def processed_message
        case [process_type, processor.id == model.user_id]
        when [:approved, true]
          'Auto-Approved'
        when [:approved, false]
          "Approved by #{processor.name} with message '#{reason_message}'"
        when [:denied, true]
          'Auto-Denied'
        when [:denied, false]
          if reason_message
            "Denied by #{processor.name} with message '#{reason_message}'"
          else
            "Denied by #{processor.name} with no message"
          end
        else
          'Unhandled state change.'
        end
      end

      def processor
        context
      end

      def reason_message
        params[:data][:attributes][:reason_message]
      end

      def process_type
        params[:data][:attributes][:approval].to_sym == :approve ? :approved : :denied
      end
    end
  end
end
