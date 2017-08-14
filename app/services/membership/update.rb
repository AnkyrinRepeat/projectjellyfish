class Membership < ApplicationRecord
  class Update < ApplicationService
    include Model
    include Policy
    include Sanitize
    include Validation

    model Membership, :find
    policy MembershipPolicy

    sanitize do
      required(:data).schema do
        required(:type, :string).filled(eql?: 'memberships')
        required(:attributes).schema do
          required(:role, :string).filled
          optional(:locked, :bool).maybe(:bool?)
        end
      end
    end

    validation do
      required(:role, :string).filled(included_in?: Membership.roles.keys)

      validate role_permitted?: :role do |role|
        membership = Membership.where(project_id: model.project_id, user_id: context.id).first

        allowed_roles = if membership.nil?
                          %w(user manager)
                        else
                          case membership.role
                          when 'owner'
                            %w(owner admin manager user)
                          when 'admin'
                            %w(admin manager user)
                          when 'manager'
                            %w(manager user)
                          else
                            %w(user)
                          end
                        end

        allowed_roles.include? role
      end
    end

    def perform
      validate params[:data][:attributes], error_nesting: %i(data attributes) do
        model.update params[:data][:attributes]
      end
    end
  end
end
