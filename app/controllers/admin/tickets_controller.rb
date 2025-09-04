# app/controllers/admin/tickets_controller.rb
module Admin
  class TicketsController < Admin::BaseController
    before_action :set_ticket, only: [:show, :update, :resolve, :close]

    def index
      scope = Ticket.order(created_at: :desc)

      # Optional filters
      scope = scope.where(status: params[:status]) if params[:status].present?
      scope = scope.where("subject ILIKE :q OR body ILIKE :q", q: "%#{params[:q]}%") if params[:q].present?

      @tickets = scope.page(params[:page]).per(20)  # <-- paginate here

      # KPI counts
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
      @ticket = Ticket.new(ticket_params.merge(user: current_user))
      if @ticket.save
        redirect_to admin_ticket_path(@ticket), notice: "Ticket created."
      else
        render :new, status: :unprocessable_entity
      end
    end

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