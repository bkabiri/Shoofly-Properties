# app/controllers/seller/accounts_controller.rb
module Seller
  class AccountsController < ApplicationController
    before_action :authenticate_user!

    def show
      @user = current_user
    end

    # PATCH /seller/account/switch_to_estate_agent
    #
    # 1) Assign attributes (so the form keeps values if invalid)
    # 2) Attach uploaded logo BEFORE validation
    # 3) Flip role to :estate_agent (make sure your enum includes it!)
    # 4) Save or re-render dashboard with inline errors
    def switch_to_estate_agent
      @user = current_user

      # Assign office/contact/name first
      @user.assign_attributes(account_params)

      # Attach uploaded logo BEFORE validation (if provided)
      uploaded_logo = params.dig(:user, :logo)
      if uploaded_logo.present?
        @user.logo.purge_later if @user.logo.attached?
        @user.logo.attach(uploaded_logo)
      end

      # Flip role so estate_agent? validations apply in the model
      # Ensure your User enum contains :estate_agent
      @user.role = :estate_agent if User.roles.key?("estate_agent")

      if @user.save
        redirect_to seller_dashboard_path, notice: "Your account is now Estate Agent."
      else
        # Keep the form open and show inline errors without losing input
        flash.now[:show_agent_form] = true

        # Ensure the dashboard has the data it expects
        @stats ||= {
          active_listings: 0,
          unread_messages: 0,
          upcoming_viewings: 0,
          this_month_views: 0
        }
        @billing_overview ||= { plan: "Free", next_invoice_on: nil, amount: "£0.00" }

        render "seller/dashboards/show", status: :unprocessable_entity
      end
    end

    # PATCH /seller/account/switch_to_private_seller
    def switch_to_private_seller
      @user = current_user
      target_role = User.roles.key?("seller") ? :seller : :buyer

      if @user.update(role: target_role)
        redirect_to seller_dashboard_path, notice: "Your account is now Private Seller."
      else
        redirect_back fallback_location: seller_dashboard_path,
                      alert: @user.errors.full_messages.to_sentence
      end
    end

    # PATCH /seller/account/update_office_details
    def update_office_details
      @user = current_user

      uploaded_logo = params.dig(:user, :logo)
      if uploaded_logo.present?
        @user.logo.purge_later if @user.logo.attached?
        @user.logo.attach(uploaded_logo)
      end

      if @user.update(account_params)
        redirect_to seller_dashboard_path, notice: "Office details updated."
      else
        flash.now[:show_agent_form] = true
        @stats ||= {
          active_listings: 0,
          unread_messages: 0,
          upcoming_viewings: 0,
          this_month_views: 0
        }
        @billing_overview ||= { plan: "Free", next_invoice_on: nil, amount: "£0.00" }
        render "seller/dashboards/show", status: :unprocessable_entity
      end
    end

    private

    def account_params
      params.require(:user).permit(
        :estate_agent_name,
        :office_address_line1, :office_address_line2,
        :office_city, :office_county, :office_postcode,
        :landline_phone, :mobile_phone
      )
    end
  end
end