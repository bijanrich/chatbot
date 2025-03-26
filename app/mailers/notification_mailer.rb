class NotificationMailer < ApplicationMailer
  default from: "onboarding@resend.dev"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.notification_mailer.welcome_email.subject
  #
  # Welcome email sent to new users after registration
  def welcome_email(user)
    @user = user
    @greeting = "Hello #{@user.name || @user.email.split('@').first}"
    @login_url = "https://your-app-url.com/login"

    mail(
      to: @user.email,
      subject: "Welcome to Our Platform"
    )
  end
end
