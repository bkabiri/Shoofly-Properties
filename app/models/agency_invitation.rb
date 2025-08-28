class AgencyInvitation < ApplicationRecord
  ROLES = %w[manager staff viewer].freeze

  belongs_to :agency, class_name: "User"
  before_validation :ensure_token, on: :create

  validates :email, presence: true
  validates :role,  inclusion: { in: ROLES }
  validates :token, presence: true, uniqueness: true

  scope :pending, -> { where(accepted_at: nil) }

  def accept!(joining_user)
    transaction do
      AgencyMembership.create!(
        agency: agency,
        user: joining_user,
        role: role
      )
      update!(accepted_at: Time.current)
    end
  end

  private

  def ensure_token
    self.token ||= SecureRandom.urlsafe_base64(24)
  end
end