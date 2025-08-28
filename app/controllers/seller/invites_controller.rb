# app/controllers/seller/invites_controller.rb
module Seller
  class InvitesController < ApplicationController
    before_action :authenticate_user!, except: [:accept]

    def index
      # List pending invites (stub)
      @invites = []  # replace with Invite.where(owner: current_user)
    end

    def create
      # Create and email an invite (stub)
      # Invite.create!(owner: current_user, email: params[:email], token: SecureRandom.hex(16))
      redirect_to seller_invites_path, notice: "Invite created (stub)."
    end

    def destroy
      # Revoke invite (stub)
      redirect_to seller_invites_path, notice: "Invite revoked (stub)."
    end

    def resend
      # Resend email (stub)
      redirect_to seller_invites_path, notice: "Invite resent (stub)."
    end

    # Public
    def accept
      # Lookup by token and show a “Join”/sign-up flow
      # invite = Invite.find_by!(token: params[:token])
      # render :accept
      render plain: "Invite acceptance page (stub) for token=#{params[:token]}"
    end
  end
end