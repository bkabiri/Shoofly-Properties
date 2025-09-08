module Admin
  class ImpersonationsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!

    def create
      user = User.find(params[:user_id])
      session[:admin_id] = current_user.id
      sign_in(user)
      redirect_to root_path, notice: "Now impersonating #{user.email}"
    end

    def destroy
      admin = User.find_by(id: session[:admin_id])
      if admin
        sign_in(admin)
        session.delete(:admin_id)
        redirect_to admin_dashboard_path, notice: "Stopped impersonation."
      else
        redirect_to root_path, alert: "No impersonation session found."
      end
    end

    private

    def require_admin!
      redirect_to(root_path, alert: "Admins only.") unless current_user&.admin?
    end
  end
end