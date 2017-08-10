class ApplicationMailer < ActionMailer::Base
  layout 'mailer'

  before_action :setup_mailer
  # Set the default sender; Change as needed in each mailer method
  default from: proc { AppSetting.current.mail_sender }

  def setup_mailer
    settings = AppSetting.current

    mail_settings = {
      address: settings.mail_host,
      port: settings.mail_port,
      openssl_verify_mode: settings.mail_ssl_verify
    }

    if settings.mail_username.present?
      mail.settings.merge!(user_name: settings.mail_username,
                           password: settings.mail_password,
                           authentication: settings.mail_authentication)
    end

    # Should be little need to override any of these settings in the mailer methods
    ActionMailer::Base.smtp_settings = mail_settings
  end
end
