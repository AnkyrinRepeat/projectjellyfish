class AppSetting < ApplicationRecord
  class Update < ApplicationService
    include Model
    include Policy
    include Sanitize
    include Validation

    model AppSetting, :update
    policy AppSettingPolicy

    sanitize do
      required(:data).schema do
        required(:type, :string).filled(eql?: 'app_settings')
        required(:attributes).schema do
          optional(:enable_signin, :bool).maybe(:bool?)
          optional(:enable_signup, :bool).maybe(:bool?)
          optional(:enable_remote, :bool).maybe(:bool?)

          optional(:mail_host, :string).maybe(:str?)
          optional(:mail_port, :string).maybe(:str?)
          optional(:mail_username, :string).maybe(:str?)
          optional(:mail_password, :string).maybe(:str?)
          optional(:mail_sender, ApplicationRecord::Types::EMAIL).maybe(format?: ApplicationRecord::Types::EMAIL_REGEXP)
        end
      end
    end

    validation do
      # TODO: For now it's redundant; expand as needed
      optional(:enable_signin).maybe(:bool?)
      optional(:enable_signup).maybe(:bool?)
      optional(:enable_remote).maybe(:bool?)

      optional(:mail_host).maybe(:str?)
      optional(:mail_port).maybe(:str?)
      optional(:mail_username).maybe(:str?)
      optional(:mail_password).maybe(:str?)
      optional(:mail_sender).maybe(format?: ApplicationRecord::Types::EMAIL_REGEXP)
    end

    def perform
      validate params[:data][:attributes], error_nesting: %i(data attributes) do |data|
        model.update data
      end
    end

    private

    def update_model!
      AppSetting.current
    end
  end
end
