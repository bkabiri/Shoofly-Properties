# app/models/user.rb
class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # --- Associations ---
  has_many :listings, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :saved_listings, through: :favorites, source: :listing

  # --- Attachments ---
  has_one_attached :logo   # used as company logo for estate agents

  # --- Roles ---
  # If you’ve already added estate_agent via migration:
  # enum role: { buyer: 0, seller: 1, estate_agent: 2, admin: 3 }
  #
  # Otherwise keep the safe default below until you migrate.
  enum role: { buyer: 0, seller: 1, estate_agent: 2, admin: 3 }

  # --- Convenience helpers ---
  def seller?
    role == "seller" || role == "estate_agent"
  end

  def estate_agent?
    role == "estate_agent"
  end

  # --- Estate Agent validations ---
  with_options if: :estate_agent? do
    validates :estate_agent_name, presence: true
    validates :office_address_line1, :office_city, :office_postcode, presence: true
    validates :landline_phone, :mobile_phone, presence: true
    validate  :logo_must_be_attached
  end

  private

  def logo_must_be_attached
    errors.add(:logo, "must be attached") unless logo.attached?
  end
end