# app/models/ticket.rb
class Ticket < ApplicationRecord
  belongs_to :requester,   class_name: "User", optional: true
  belongs_to :assigned_to, class_name: "User", optional: true

  enum status:   { open: 0, pending: 1, resolved: 2, closed: 3 }
  enum priority: { low: 0, normal: 1, high: 2, urgent: 3 }

  validates :subject, presence: true
end