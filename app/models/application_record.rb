class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  module Types
    include Dry::Types.module

    EMAIL_REGEXP = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/
    EMAIL = String.constructor { |value| value.to_s.downcase.strip unless value.nil? }

    HOST_REGEXP = %r{\Ahttps?://.+}i
    HOST = String.constructor { |value| value.to_s.downcase.strip unless value.nil? }

    UUID_REGEXP = /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/
    UUID = String.constructor { |value| value.to_s.downcase.strip unless value.nil? }

    PRICE_REGEXP = /\A\d{1,6}(?:\.\d{1,4})?\z/
    BUDGET_REGEXP = /\A\d{1,10}(?:\.\d{1,2})?\z/

    def self.name_value_pair
      Dry::Validation.Schema do
        required(:name).filled(:str?)
        required(:value).filled(:str?)
      end
    end

    def self.identifier(type)
      Dry::Validation.Schema do
        required(:type).filled(eql?: type)
        required(:id).filled(:str?)
      end
    end
  end

  module Encryption
    def encrypt(value)
      crypt.encrypt_and_sign(value)
    end

    def decrypt(encrypted_value)
      crypt.decrypt_and_verify(encrypted_value) unless encrypted_value.nil?
    end

    private

    def crypt
      secret_key_base = Rails.application.secrets.secret_key_base
      ActiveSupport::MessageEncryptor.new(secret_key_base)
    end
  end

  include Encryption
  extend Encryption

  def type_name
    @type_name ||= self.class.to_s.underscore
  end
end
