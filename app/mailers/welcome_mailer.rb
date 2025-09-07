# app/mailers/welcome_mailer.rb
class WelcomeMailer < ApplicationMailer
  default from: ENV.fetch("MAILER_SENDER", "no-reply@snoofly.com")

  def welcome_email(user_id)
    @user = User.find(user_id)
    mail to: @user.email, subject: "Welcome to Snoofly 🎉"
  end
end