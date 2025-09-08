# app/controllers/admin/users_controller.rb
module Admin
  class UsersController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_user, only: [:show, :edit, :update, :destroy, :block]

    def show; end
    def edit; end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "User updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @user.destroy
      redirect_to admin_dashboard_path, notice: "User deleted."
    end

    def block
      if @user.respond_to?(:blocked)
        @user.update(blocked: true)
      elsif @user.respond_to?(:status)
        @user.update(status: "blocked")
      else
        # fallback: add your own flag/logic
      end
      redirect_to admin_dashboard_path, notice: "User blocked."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:full_name, :email, :role) # extend as needed
    end

    def require_admin!
      redirect_to root_path, alert: "Admins only." unless current_user&.admin?
    end
  end
end