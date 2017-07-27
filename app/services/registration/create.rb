module Registration
  class Create < ApplicationService
    include Policy
    include Sanitize

    policy RegistrationPolicy

    sanitize do
      required(:data).schema do
        required(:type, :string).filled(eql?: 'users')
        required(:attributes, :hash).filled(:hash?)
      end
    end

    def perform
      run_service User::Create do |success|
        @model = success.model
        send_registration_email(success.model)
      end
    end

    private

    def finalize_params!
      # Registrations are disabled at first; Accounts must be activated
      params[:data][:attributes][:state] = 'pending'
      params[:data][:attributes][:role] = 'user'
    end

    def send_registration_email(user)
      UserMailer.registration(user).deliver_later
    end
  end
end
