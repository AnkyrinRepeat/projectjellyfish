class RemoteAuthSession
  class Create < ApplicationService
    include Model
    include Sanitize
    include Validation

    model User, :find

    sanitize do
      required(:user_agent, :string).filled
      required(:remote_ip, :string).filled
      required(:remote_user, User::Types::EMAIL).filled(format?: User::Types::EMAIL_REGEXP)
      required(:name, :string).filled
    end

    validation do
      required(:user_agent, :string).filled
      required(:remote_ip, :string).filled
      required(:remote_user, User::Types::EMAIL).filled(format?: User::Types::EMAIL_REGEXP)
      required(:name, :string).filled

      # We activated new accounts, but have to check existing accounts
      validate active?: [:email] do
        model.active?
      end
    end

    def perform
      validate do
        UserMailer.welcome(model.name, model.email).deliver_later unless model.persisted?

        model.last_login_at = DateTime.current
        model.last_client_info = login_info
        model.regenerate_session_token # Saves the user record
      end
    end

    def find_model!
      User.find_or_initialize_by(email: params[:remote_user]) do |u|
        u.name = params[:name]
        # adding a random password since the user model requires a password
        u.password = u.password_confirmation = SecureRandom.base64(12)
        # Bypassing state machine activation actions and marking user as active
        u.state = 'active'
      end
    rescue
      raise Goby::Exceptions::ValidationErrors, [{ path: %w(data attributes email), predicate: 'email',
                                                   text: 'Could not authenticate user' }]
    end

    def login_info
      "#{params[:remote_ip]} #{params[:user_agent]}"
    end
  end
end
