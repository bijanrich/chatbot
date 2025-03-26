class SubscriptionMailer < ApplicationMailer
  default from: 'billing@fanpilot.app'

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.subscription_mailer.subscription_confirmation.subject
  #
  def subscription_confirmation(organization)
    @organization = organization
    @subscription = organization.subscriptions.active.first
    @plan = Plan.find_by(name: @subscription.plan_name) if @subscription

    mail(
      to: organization.billing_email,
      subject: 'Your FanPilot Subscription Confirmation'
    )
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.subscription_mailer.payment_failed.subject
  #
  def payment_failed(organization, invoice)
    @organization = organization
    @subscription = organization.subscriptions.find_by(status: 'past_due')
    @invoice = invoice
    @amount = invoice.amount_due / 100.0 # Convert cents to dollars
    @payment_url = invoice.hosted_invoice_url

    mail(
      to: organization.billing_email,
      subject: 'FanPilot Payment Failed: Action Required'
    )
  end
end
