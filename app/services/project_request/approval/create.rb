class ProjectRequest < ApplicationRecord
  class Approval
    class Create < ApplicationService
      include Model
      include Policy
      include Sanitize

      model ProjectRequest, :update
      policy ProjectRequestPolicy, :approval?

      sanitize do
        required(:project_request_id, ApplicationRecord::Types::UUID).filled(format?: ApplicationRecord::Types::UUID_REGEXP)
        required(:data).schema do
          required(:type, :string).filled(eql?: 'project_request/approvals')
          required(:attributes).schema do
            required(:approval, :string).filled(included_in?: %w(approve deny))
            optional(:budget, :string).maybe(format?: ApplicationRecord::Types::BUDGET_REGEXP)
            optional(:reason_message, :string).maybe(:str?)
          end
        end
      end

      def perform
        if model.pending?
          model.processor_id = processor.id
          model.budget = budget
          model.status = process_type
          model.processed_at = DateTime.current
          model.processed_message = processed_message

          model.save

          if model.approved?
            create_project

            ProjectRequestMailer.approved(model).deliver_later
          end

          if model.denied?
            ProjectRequestMailer.denied(model).deliver_later
          end
        end
      end

      private

      def create_project
        project = model.create_project name: model.name, budget: budget, last_hourly_compute_at: DateTime.current, last_monthly_compute_at: DateTime.current
        project.memberships.create user_id: model.user_id, role: :owner, locked: true
        model.save
      end

      def model_id
        params[:project_request_id]
      end

      def budget
        params[:data][:attributes][:budget] || model.budget
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
