# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user   # author

  validates :body, presence: true

  # After saving, push this message to both participants' Turbo streams
  after_create_commit :broadcast_to_participants

  private

  def broadcast_to_participants
    participant_ids = [conversation.buyer_id, conversation.seller_id].compact.uniq

    participant_ids.each do |viewer_id|
      broadcast_append_later_to(
        [:conversation, conversation.id, :user, viewer_id],
        target: "messages_list_#{conversation.id}",
        partial: "messages/message",
        locals: {
          message: self,
          viewer_id: viewer_id
        }
      )
    end
  end
end