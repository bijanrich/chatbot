puts "Creating test organization..."
test_org = Organization.find_or_create_by!(
  name: 'Test Organization',
  billing_email: 'billing@test.com'
)

puts "Creating test user..."
test_user = User.find_or_initialize_by(email: 'test@test.com')
test_user.password = 'lkj3lkj3'
test_user.password_confirmation = 'lkj3lkj3'
test_user.skip_confirmation! # Skip email confirmation for the test user
test_user.save!

# Create associated creator profile
CreatorProfile.find_or_create_by!(
  user_id: test_user.id,
  organization: test_org,
  name: 'Test Creator',
  onlyfans_username: 'test_creator',
  status: 'active'
)

puts "Test user created successfully!"
puts "Email: test@test.com"
puts "Password: lkj3lkj3" 