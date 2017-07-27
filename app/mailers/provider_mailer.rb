class ProviderMailer < ApplicationMailer
  def disconnected(provider)
    @provider = provider
    bcc_list = User.where(role: :admin, state: :active).pluck(:email)
    mail bcc: bcc_list, subject: default_i18n_subject(
      provider_type: provider.type.deconstantize, name: provider.name
)
  end
end
