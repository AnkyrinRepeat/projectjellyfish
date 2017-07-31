class Session
  include ActiveModel::Model

  attr_reader :user
  attr_reader :token

  def initialize(params)
    @user = params[:user]
    @token = nil
  end

  def token
    return @token unless @token.nil?
    Session.build_token(user) if user
  end

  class << self
    def build_token(user)
      payload = {
        sub: [user.id, user.session_token].join(':'),
        exp: Time.now.to_i + 7.days,
        iat: DateTime.current.to_i,
        iss: token_issuer
      }
      JWT.encode payload, token_secret, token_algorithm
    end

    def parse_token(token)
      options = {
        verify_iat: true,
        iss: token_issuer,
        verify_iss: true,
        algorithm: token_algorithm
      }
      JWT.decode token, token_secret, true, options
    end

    private

    def token_issuer
      Rails.application.secrets.jwt_issuer || 'API'
    end

    def token_secret
      Rails.application.secrets.secret_key_base
    end

    def token_algorithm
      Rails.application.secrets.jwt_algorithm || 'HS512'
    end
  end
end
