# app/controllers/admin/tickets_controller.rb
module Admin
  class TicketsController < Admin::BaseController
    before_action :set_ticket, only: [:show, :update, :resolve, :close]

    def index
      scope = Ticket.order(created_at: :desc)
      scope = scope.where(status: params[:status]) if params[:status].present?
      scope = scope.where("subject ILIKE :q OR body ILIKE :q", q: "%#{params[:q]}%") if params[:q].present?
      @tickets = scope.page(params[:page]).per(20)

      @open_count     = Ticket.open.count
      @pending_count  = Ticket.pending.count
      @resolved_count = Ticket.resolved.count
      @closed_count   = Ticket.closed.count
    end

    def show; end

    def new
      @ticket = Ticket.new
    end

    def create
      # ✅ set requester (the user who opened the ticket)
      @ticket = Ticket.new(ticket_params.merge(requester: current_user))
      if @ticket.save
        redirect_to admin_ticket_path(@ticket), notice: "Ticket created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      # Don’t overwrite assignee here; let the permitted param do it.
      if @ticket.update(ticket_params)
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
      # include :assigned_to_id (matches belongs_to :assigned_to)
      params.require(:ticket).permit(:subject, :body, :status, :priority, :assigned_to_id, :attachment)
    end
  end
end