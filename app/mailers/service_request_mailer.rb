class ServiceRequestMailer < ApplicationMailer
  def admin_manager_notice(project, owner, count)
    @count = count
    @project = project
    @owner = owner
    @site_url = Rails.application.routes.url_helpers.root_url

    bcc_list = User.where(role: %i(manager admin), state: :active).pluck(:email)

    mail bcc: bcc_list, subject: "Service #{'request'.pluralize(count)} created by #{owner.name} for #{project.name}"
  end

  def owner_notice(project, owner, count)
    @count = count
    @project = project
    @owner = owner

    mail to: owner.email, subject: "You have created #{count} service #{'request'.pluralize(count)} for #{project.name}"
  end

  def approval(service_request)
    @service_request = service_request
    @owner = service_request.user

    mail to: service_request.user.email, subject: default_i18n_subject(service_name: service_request.service_name)
  end

  def denial(service_request)
    @service_request = service_request
    @owner = service_request.user

    mail to: service_request.user.email, subject: default_i18n_subject(service_name: service_request.service_name)
  end
end
