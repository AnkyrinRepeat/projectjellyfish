class ServiceMailer < ApplicationMailer
  def error_alert(service)
    @service = service
    bcc_list = User.where(role: :admin, state: :active).pluck(:email)

    mail to: bcc_list, subject: default_i18n_subject(name: service.name)
  end
end
