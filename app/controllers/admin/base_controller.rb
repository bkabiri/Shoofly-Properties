# app/controllers/admin/base_controller.rb
module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!

    layout "application"   # <- use the normal layout

    private
    def require_admin!
      redirect_to root_path, alert: "Admins only." unless current_user&.admin?
    end
  end
end