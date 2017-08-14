class AppSettingSerializer < ApplicationSerializer
  attributes :enable_signin, :enable_signup
  attributes :enable_remote
  attributes :mail_host, :mail_port, :mail_username, :mail_sender

  def available_fields
    fields = super

    # Allowed Anonymous settings
    anon_settings = %i(enable_signin enable_signup enable_remote)
    return anon_settings if context.blank?

    unless context.admin?
      fields -= %i(mail_host mail_port mail_username mail_sender)
    end

    fields
  end
end
