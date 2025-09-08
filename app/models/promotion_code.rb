# app/models/promotion_code.rb
class PromotionCode < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true

  KINDS = %w[free_listing].freeze

  before_validation :normalize_code
  before_validation :generate_code_if_blank

  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :kind, inclusion: { in: KINDS }
  validates :usage_limit, numericality: { only_integer: true, greater_than: 0 }
  validates :used_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where(active: true) }

  def usable_now?
    active &&
      (starts_at.blank?  || starts_at <= Time.current) &&
      (expires_at.blank? || expires_at >= Time.current) &&
      used_count < usage_limit
  end

  def increment_use!
    with_lock do
      raise StandardError, "Usage limit reached" if used_count >= usage_limit
      update!(used_count: used_count + 1)
    end
  end

  private

  def normalize_code
    self.code = code.to_s.strip.upcase
  end

  def generate_code_if_blank
    return if code.present?
    self.code = loop do
      candidate = SecureRandom.alphanumeric(8).upcase
      break candidate unless self.class.exists?(code: candidate)
    end
  end
end