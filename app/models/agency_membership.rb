class AgencyMembership < ApplicationRecord
  ROLES = %w[manager staff viewer].freeze

  belongs_to :agency, class_name: "User" # the agent account owner
  belongs_to :user                      # the member user

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :agency_id }
end