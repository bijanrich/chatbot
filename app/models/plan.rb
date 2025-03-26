class Plan < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :interval, presence: true, inclusion: { in: ['month', 'year'] }
  validates :stripe_price_id, uniqueness: true, allow_nil: true
  
  # Serialized attributes
  serialize :features, coder: JSON
  
  # Scopes
  scope :active, -> { where.not(stripe_price_id: nil) }
  scope :monthly, -> { where(interval: 'month') }
  scope :yearly, -> { where(interval: 'year') }
  
  # Format price for display
  def formatted_price
    case interval
    when 'month'
      "$#{amount.to_i}/month"
    when 'year'
      "$#{amount.to_i}/year"
    else
      "$#{amount.to_i}"
    end
  end
  
  # Get features as an array
  def features_list
    features.is_a?(Array) ? features : features.to_s.split(',').map(&:strip)
  end
  
  # Check if plan is monthly
  def monthly?
    interval == 'month'
  end
  
  # Check if plan is yearly
  def yearly?
    interval == 'year'
  end
end
