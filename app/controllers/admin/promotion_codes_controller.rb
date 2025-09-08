# app/controllers/admin/promotion_codes_controller.rb
module Admin
  class PromotionCodesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_promo, only: [:update, :destroy]

    def index
      @promotion_codes = PromotionCode.recent.limit(200)
      render partial: "admin/dashboard_sections/promo_codes", formats: :html
    end

    def create
      @promotion_code = PromotionCode.new(promo_params.merge(created_by: current_user))
      if @promotion_code.save
        redirect_to admin_dashboard_path(anchor: "tab-promos"), notice: "Promotion code created."
      else
        redirect_to admin_dashboard_path(anchor: "tab-promos"),
                    alert: @promotion_code.errors.full_messages.to_sentence
      end
    end

    def update
      if @promo.update(promo_params)
        redirect_to admin_dashboard_path(anchor: "tab-promos"), notice: "Promotion code updated."
      else
        redirect_to admin_dashboard_path(anchor: "tab-promos"),
                    alert: @promo.errors.full_messages.to_sentence
      end
    end

    def destroy
      @promo.destroy
      redirect_to admin_dashboard_path(anchor: "tab-promos"), notice: "Promotion code deleted."
    end

    private

    def set_promo
      @promo = PromotionCode.find(params[:id])
    end

    def promo_params
      params.require(:promotion_code).permit(
        :code, :kind, :usage_limit, :starts_at, :expires_at, :active
      )
    end

    def require_admin!
      redirect_to(root_path, alert: "Admins only.") unless current_user&.admin?
    end
  end
end