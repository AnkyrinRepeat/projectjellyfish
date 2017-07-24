class Provider < ApplicationRecord
  class CheckCredentials < ApplicationService
    include Model

    model Provider, :find

    def perform
      model.valid_credentials?
      model.status_message = 'OK'
      model.credentials_message = 'valid'
      model.connected = true
      model.last_connected_at = DateTime.current
    rescue => error
      model.connected = false
      model.status_message = error.message
      model.credentials_message = 'validation failed'
    ensure
      model.credentials_validated_at = DateTime.now.utc
      model.save
      ProviderMailer.disconnected(model).deliver_later unless model.connected
    end

    private

    def recently_checked_credentials?
      model.credentials_validated_at >= 1.minute.ago
    end
  end
end
