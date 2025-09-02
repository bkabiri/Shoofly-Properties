# app/controllers/seller/accounts_controller.rb
module Seller
  class AccountsController < ApplicationController
    before_action :authenticate_user!

    def show
      @user = current_user
    end

    # PATCH /seller/account/switch_to_estate_agent
    # Collect agency details + logo, mark the account as "requested_estate_agent",
    # and let an admin approve the switch in the Admin dashboard.
    def switch_to_estate_agent
      @user = current_user

      # 1) Assign office/contact/name first so values stick on validation errors
      @user.assign_attributes(account_params)

      # 2) Handle logo upload BEFORE save
      if (uploaded_logo = params.dig(:user, :logo)).present?
        @user.logo.purge_later if @user.logo.attached?
        @user.logo.attach(uploaded_logo)
      end

      # 3) Mark as pending request (do NOT flip role here)
      @user.requested_estate_agent = true

      if @user.save
        redirect_to seller_dashboard_path,
          notice: "Thanks! Your request to become an Estate Agent has been submitted. We'll notify you once it's approved."
      else
        # Keep the modal open and render dashboard with inline errors
        flash.now[:show_agent_form] = true

        # Provide dashboard fallbacks
        @stats ||= { active_listings: 0, unread_messages: 0, upcoming_viewings: 0, this_month_views: 0 }
        @billing_overview ||= { plan: "Free", next_invoice_on: nil, amount: "£0.00" }

        render "seller/dashboards/show", status: :unprocessable_entity
      end
    end

    # PATCH /seller/account/switch_to_private_seller
    def switch_to_private_seller
      @user = current_user
      target_role = User.roles.key?("seller") ? :seller : :buyer

      if @user.update(role: target_role, requested_estate_agent: false)
        redirect_to seller_dashboard_path, notice: "Your account is now Private Seller."
      else
        redirect_back fallback_location: seller_dashboard_path,
                      alert: @user.errors.full_messages.to_sentence
      end
    end

    # PATCH /seller/account/update_office_details
    def update_office_details
      @user = current_user

      if (uploaded_logo = params.dig(:user, :logo)).present?
        @user.logo.purge_later if @user.logo.attached?
        @user.logo.attach(uploaded_logo)
      end

      if @user.update(account_params)
        redirect_to seller_dashboard_path, notice: "Office details updated."
      else
        flash.now[:show_agent_form] = true
        @stats ||= { active_listings: 0, unread_messages: 0, upcoming_viewings: 0, this_month_views: 0 }
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