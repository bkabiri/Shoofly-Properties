# app/controllers/admin/tickets_controller.rb
module Admin
  class TicketsController < Admin::BaseController
    before_action :set_ticket, only: [:show, :update, :resolve, :close]

    def index
      @q = Ticket.order(created_at: :desc)
      @tickets = @q
      @open_count    = Ticket.open.count
      @pending_count = Ticket.pending.count
      @resolved_count= Ticket.resolved.count
      @closed_count  = Ticket.closed.count
    end

    def show; end

    def update
      if @ticket.update(ticket_params.merge(assigned_to: current_user))
        redirect_to admin_ticket_path(@ticket), notice: "Ticket updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    def resolve
      @ticket.update!(status: :resolved)
      redirect_to admin_ticket_path(@ticket), notice: "Ticket resolved."
    end

    def close
      @ticket.update!(status: :closed)
      redirect_to admin_ticket_path(@ticket), notice: "Ticket closed."
    end

    private
    def set_ticket
      @ticket = Ticket.find(params[:id])
    end

    def ticket_params
      params.require(:ticket).permit(:subject, :body, :status, :priority, :assigned_to_id)
    end
  end
end