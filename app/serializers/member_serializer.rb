class MemberSerializer < ApplicationSerializer
  attributes :membership_id, :project_id, :user_id
  attributes :role, :locked, :user_name, :email, :project_name
  attributes :created_at, :updated_at

  def _id
    object.membership_id
  end

  def available_fields
    fields = super

    unless context.admin?
      fields -= %i(email)
    end

    fields
  end
end
