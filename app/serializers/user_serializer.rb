class UserSerializer < ApplicationSerializer
  attributes :name, :email, :role, :state
  attributes :last_login_at, :last_client_info, :last_failed_login_at, :last_failed_client_info
  attributes :created_at, :updated_at

  field :avatar_url

  filter :like
  filter :with_states

  has_many :memberships
  has_many :projects

  def avatar_url
    ['https://www.gravatar.com/avatar/', Digest::MD5.hexdigest(object.email), '?d=mm&r=pg&s=100'].join ''
  end

  def available_fields
    fields = super

    return %i[name avatar_url] if context.blank?

    unless context == object || context.admin?
      fields -= %i[email role last_login_at last_login_client_info created_at updated_at]
    end

    unless context.admin?
      fields -= %i[last_failed_login_at last_failed_client_info]
    end

    fields
  end
end
