class AppSetting < ApplicationRecord
  CACHE_KEY = 'app_settings'.freeze

  after_commit do
    begin
      Rails.cache.write(CACHE_KEY, self)
    rescue TypeError
      raise unless Rails.env.development?
    end
  end

  def self.current
    Rails.cache.fetch(CACHE_KEY) do
      AppSetting.order(created_at: :desc).first
    end
  end

  def self.expire
    Rails.cache.delete(CACHE_KEY)
  end

  def self.cached
    Rails.cache.fetch(CACHE_KEY)
  end

  def self.create_defaults
    create(
      # Authentication Settings
      enable_signup: true,
      enable_signin: true,

      # Remote Authentication Settings
      enable_remote: false,

      # SAML Authentication Settings
      enable_saml: false,

      # Cost Quotas
      project_budget_maximum: 100_000,
      user_default_monthly_maximum: 1_000,

      # Automatics
      auto_approve_services: false,

      # SMTP/Mailer settings
      mail_host: '127.0.0.1',
      mail_port: '1025',
      mail_username: nil,
      mail_password: nil,
      mail_authentication: 'plain',
      mail_ssl_verify: 'none',
      mail_sender: '',

      # Logging/Notification settings
      system_notification_email: ''
    )
  end
end
