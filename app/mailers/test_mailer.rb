class TestMailer < ApplicationMailer
  def test_email(destination)
    mail to: destination
  end
end
