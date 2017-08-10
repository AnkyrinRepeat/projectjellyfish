class User < ApplicationRecord
  MIN_PASSWORD_LENGTH = 6

  has_secure_password
  has_secure_token :session_token
  has_secure_token :reset_password_token

  has_many :memberships, dependent: :destroy
  has_many :projects, through: :memberships

  enum role: { user: 0, manager: 1, admin: 2 }

  scope :like, ->(query) { where('users.name ILIKE :query OR LOWER(users.email) LIKE :query', query: "#{query.downcase.gsub(/%|_/, '\\\\\0')}%") }

  state_machine :state, initial: :pending do
    before_transition any => :active, do: :activate_user
    before_transition active: :disabled, do: :deactivate_user
    after_transition on: :approve, do: :send_approval_email

    event :approve do
      transition pending: :active
    end

    event :disable do
      transition active: :disabled
    end

    event :enable do
      transition disabled: :active
    end

    state :pending
    state :active
    state :disabled
  end

  module Predicates
    include Dry::Logic::Predicates

    predicate(:unique_email?) do |value|
      User.where(email: value).none?
    end
  end

  def session
    Session.new user: self
  end

  def activate_user
    self[:disabled_at] = nil
  end

  def deactivate_user
    self[:disabled_at] = DateTime.current
  end

  def send_approval_email
    UserMailer.approval(self).deliver_later
  end
end
