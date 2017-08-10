class Membership < ApplicationRecord
  class Create < ApplicationService
    include Model
    include Policy
    include Sanitize
    include Validation

    model Membership, :create
    policy MembershipPolicy

    sanitize do
      required(:data).schema do
        required(:type, :string).filled(eql?: 'memberships')
        required(:attributes).schema do
          required(:user_id, ApplicationRecord::Types::UUID).filled(format?: ApplicationRecord::Types::UUID_REGEXP)
          required(:project_id, ApplicationRecord::Types::UUID).filled(format?: ApplicationRecord::Types::UUID_REGEXP)
          optional(:locked, :bool).maybe(:bool?)
        end
      end
    end

    validation do
      configure do
        def user_exists?(user_id)
          User.where(id: user_id).exists?
        end

        def project_exists?(project_id)
          Project.where(id: project_id).exists?
        end
      end

      required(:user_id).filled(:user_exists?)
      required(:project_id).filled(:project_exists?)

      validate member_already?: %i[user_id product_id] do |user_id, project_id|
        !Membership.where(user_id: user_id, project_id: project_id).exists?
      end
    end

    def perform
      validate params[:data][:attributes], error_nesting: %i[data attributes] do
        model.update params[:data][:attributes]
      end
    rescue ActiveRecord::RecordNotUnique
      raise Goby::Exceptions::RecordNotUnique.new, '/data/attributes'
    end

    private

    def setup_model!
      model.user_id = params[:data][:attributes][:user_id]
      model.project_id = params[:data][:attributes][:project_id]
    end
  end
end
