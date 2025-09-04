# app/models/conversation.rb
class Conversation < ApplicationRecord
  belongs_to :listing
  belongs_to :buyer,  class_name: "User"
  belongs_to :seller, class_name: "User"
  has_many   :messages, dependent: :destroy

  validates :listing_id, :buyer_id, :seller_id, presence: true

  scope :for_user, ->(user) { where("buyer_id = ? OR seller_id = ?", user.id, user.id) }

  def participant?(user)
    user && (user.id == buyer_id || user.id == seller_id)
  end
end