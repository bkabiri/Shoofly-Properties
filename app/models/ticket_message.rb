# app/models/ticket_message.rb
class TicketMessage < ApplicationRecord
  belongs_to :ticket
  belongs_to :user
  validates :body, presence: true

  after_create_commit do
    broadcast_append_to(
      [:ticket, ticket.id],
      target: "ticket_messages_#{ticket.id}",
      partial: "admin/tickets/message",
      locals: { message: self }
    )
  end
end