# Create subscription plans
puts "Creating subscription plans..."

# Starter Plan
starter = Plan.find_or_initialize_by(name: 'starter')
starter.update!(
  amount: 49.99,
  interval: 'month',
  description: 'Perfect for agencies just starting out with a few creators',
  features: [
    'Manage up to 5 creators',
    'Basic analytics',
    'Email support',
    'Content calendar'
  ]
)

# Professional Plan
professional = Plan.find_or_initialize_by(name: 'professional')
professional.update!(
  amount: 99.99,
  interval: 'month',
  description: 'Ideal for growing agencies with more creators and advanced needs',
  features: [
    'Manage up to 15 creators',
    'Advanced analytics',
    'Priority email support',
    'Content calendar',
    'AI-powered content suggestions',
    'Custom branding'
  ]
)

# Enterprise Plan
enterprise = Plan.find_or_initialize_by(name: 'enterprise')
enterprise.update!(
  amount: 199.99,
  interval: 'month',
  description: 'For established agencies with a large roster of creators',
  features: [
    'Unlimited creators',
    'Comprehensive analytics',
    'Dedicated account manager',
    'Content calendar',
    'AI-powered content suggestions',
    'Custom branding',
    'API access',
    'White-label solution'
  ]
)

# Annual starter Plan
annual_starter = Plan.find_or_initialize_by(name: 'annual_starter')
annual_starter.update!(
  amount: 499.99,
  interval: 'year',
  description: 'Starter plan with annual billing (save 16%)',
  features: [
    'Manage up to 5 creators',
    'Basic analytics',
    'Email support',
    'Content calendar'
  ]
)

# Annual Professional Plan
annual_professional = Plan.find_or_initialize_by(name: 'annual_professional')
annual_professional.update!(
  amount: 999.99,
  interval: 'year',
  description: 'Professional plan with annual billing (save 16%)',
  features: [
    'Manage up to 15 creators',
    'Advanced analytics',
    'Priority email support',
    'Content calendar',
    'AI-powered content suggestions',
    'Custom branding'
  ]
)

# Annual Enterprise Plan
annual_enterprise = Plan.find_or_initialize_by(name: 'annual_enterprise')
annual_enterprise.update!(
  amount: 1999.99,
  interval: 'year',
  description: 'Enterprise plan with annual billing (save 16%)',
  features: [
    'Unlimited creators',
    'Comprehensive analytics',
    'Dedicated account manager',
    'Content calendar',
    'AI-powered content suggestions',
    'Custom branding',
    'API access',
    'White-label solution'
  ]
)

puts "Created #{Plan.count} subscription plans." 