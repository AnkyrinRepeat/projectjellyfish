class Session
  class Create < ApplicationService
    include Model
    include Sanitize
    include Validation

    model User, :find

    sanitize do
      required(:user_agent, :string).filled
      required(:remote_ip, :string).filled
      required(:data).schema do
        required(:type, :string).filled(eql?: 'sessions')
        required(:attributes).schema do
          required(:email, User::Types::EMAIL).filled(format?: User::Types::EMAIL_REGEXP)
          required(:password, :string).filled(:str?)
        end
      end
    end

    validation do
      required(:email).filled(:str?)
      required(:password).filled(:str?)

      # TODO: Record failed logins
      validate(valid_email?: [:password, :email]) do |password, _email|
        BCrypt::Password.new(model.password_digest) == password
      end

      validate active?: [:email] do
        model.active?
      end
    end

    def perform
      validate params[:data][:attributes], error_nesting: %i(data attributes) do
        model.last_login_at = DateTime.current
        model.last_client_info = login_info
        model.regenerate_session_token # Saves the user record
      end

      # unless results.success?
      #   # For a login form we don't want to let the user know they passed in a bad password
      #   hide_password_errors
      #
      #   model.last_failed_login_at = DateTime.current
      #   model.last_failed_client_info = login_info
      #   model.save
      # end
    end

    def find_model!
      User.find_by! email: params[:data][:attributes][:email]
    rescue ActiveRecord::RecordNotFound
      raise Goby::Exceptions::ValidationErrors, [{ path: %w(data attributes email), predicate: 'password',
                                                   text: 'Email or password is incorrect' }]
    end

    # def hide_password_errors
    #   if errors.dig(:data, :attributes, :password)
    #     errors[:data] ||= {}
    #     errors[:data][:attributes] = ['Email or password is incorrect']
    #   end
    # end

    def login_info
      "#{params[:remote_ip]} #{params[:user_agent]}"
    end
  end
end
