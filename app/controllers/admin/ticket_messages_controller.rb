# app/controllers/admin/ticket_messages_controller.rb
module Admin
  class TicketMessagesController < Admin::BaseController
    def create
      @ticket  = Ticket.find(params[:ticket_id])
      @message = TicketMessage.new(ticket: @ticket, user: current_user, body: params.require(:ticket_message)[:body])

      if @message.save
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to admin_ticket_path(@ticket), notice: "Reply sent." }
        end
      else
        redirect_to admin_ticket_path(@ticket), alert: @message.errors.full_messages.to_sentence
      end
    end
  end
end