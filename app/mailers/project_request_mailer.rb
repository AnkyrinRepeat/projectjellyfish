class ProjectRequestMailer < ApplicationMailer
  def needs_approval(project_request)
    # Create BCC list of approvers
    bcc_list = User.where(role: :manager, state: :active).pluck :email

    @project_request = project_request
    @approval_url = Rails.application.routes.url_helpers.root_url + 'projects/approvals'
    mail bcc: bcc_list
  end

  def approved(project_request)
    @project_request = project_request
    @site_url = Rails.application.routes.url_helpers.root_url
    mail to: project_request.user.email, subject: default_i18n_subject(name: project_request.name)
  end

  def denied(project_request)
    @project_request = project_request
    @site_url = Rails.application.routes.url_helpers.root_url
    mail to: project_request.user.email, subject: default_i18n_subject(name: project_request.name)
  end
end
