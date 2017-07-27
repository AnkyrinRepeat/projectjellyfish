class UserMailer < ApplicationMailer
  def registration(user)
    mail to: user.email
  end

  def approval(user)
    @user = user

    mail to: user.email
  end

  def welcome(name, email)
    @name = name

    mail to: email
  end
end
