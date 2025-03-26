# Preview all emails at http://localhost:3000/rails/mailers/subscription_mailer_mailer
class SubscriptionMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/subscription_mailer_mailer/subscription_confirmation
  def subscription_confirmation
    SubscriptionMailer.subscription_confirmation
  end

  # Preview this email at http://localhost:3000/rails/mailers/subscription_mailer_mailer/payment_failed
  def payment_failed
    SubscriptionMailer.payment_failed
  end

end
