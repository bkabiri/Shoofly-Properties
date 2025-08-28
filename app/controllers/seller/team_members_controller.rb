# app/controllers/seller/team_members_controller.rb
module Seller
  class TeamMembersController < ApplicationController
    before_action :authenticate_user!
    before_action :require_agent!

    def index
      @team_members = current_user.team_members if current_user.respond_to?(:team_members)
    end

    def create
      # Implement your own join model or invite flow
      # Example placeholder:
      # TeamMember.create!(owner: current_user, email: params[:email], role: params[:role])
      redirect_to seller_team_members_path, notice: "Invite sent (stub)."
    end

    def update
      # Change role etc. (stub)
      redirect_to seller_team_members_path, notice: "Member updated (stub)."
    end

    def destroy
      # Remove member (stub)
      redirect_to seller_team_members_path, notice: "Member removed (stub)."
    end

    private

    def require_agent!
      unless current_user.respond_to?(:estate_agent?) && current_user.estate_agent?
        redirect_to seller_dashboard_path, alert: "Estate Agent access only."
      end
    end
  end
end