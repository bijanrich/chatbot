# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer_mailer
class NotificationMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/notification_mailer_mailer/welcome_email
  def welcome_email
    NotificationMailer.welcome_email
  end

end
