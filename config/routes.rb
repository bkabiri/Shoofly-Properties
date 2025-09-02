# config/routes.rb
Rails.application.routes.draw do
  # -------------------------
  # Public Listings
  # -------------------------
  resources :listings, only: [:index, :show] do
    post   :favorite,   to: "favorites#create"
    delete :unfavorite, to: "favorites#destroy"
  end

  # Saved properties (authenticated list)
  authenticate :user do
    resources :favorites, only: %i[index create destroy]
  end
  get "/saved", to: "favorites#index", as: :saved_properties

  # Tidy legacy/incorrect paths
  get "/listings/index", to: redirect("/listings")

  # -------------------------
  # Devise + Home
  # -------------------------
  get "home/index"
  devise_for :users, controllers: { registrations: "users/registrations" }
  root to: "home#index"

  # -------------------------
  # Checkout
  # -------------------------
  resources :checkout, only: [] do
    collection do
      post :sessions      # POST /checkout/sessions (Stripe session create)
      get  :success       # GET  /checkout/success
      get  :cancel        # GET  /checkout/cancel
    end
  end
  # (Alias kept if something calls this directly)
  post "/checkout_sessions", to: "checkout#sessions"

  # -------------------------
  # Authenticated Seller Area
  # -------------------------
  authenticate :user do
    namespace :seller do
      # Dashboard
      resource :dashboard, only: :show, controller: "dashboards"

      # Account type switching + office details
      resource :account, only: :show, controller: "accounts" do
        patch :switch_to_estate_agent
        patch :switch_to_private_seller
        patch :update_office_details
      end

      # Team management
      resources :team_members, only: [:index, :create, :update, :destroy], controller: "team_members"

      # Invite management
      resources :invites, only: [:index, :create, :destroy], controller: "invites" do
        post :resend, on: :member
      end

      # Seller Listings (full CRUD + utilities)
      resources :listings do
        collection { post :generate_description }
        member do
          post  :generate_description
          patch :autosave
          patch :publish
          patch :unpublish
          patch :feature
          patch :unfeature
          patch :bump
          delete :purge_banner
          delete :purge_epc
          delete :purge_photo
        end
      end
    end
  end

  # Public invite acceptance (no auth required)
  get "seller/invites/:token/accept",
      to: "seller/invites#accept",
      as: :accept_seller_invite

  # Nice alias for the seller dashboard
  get "/dashboard", to: "seller/dashboards#show", as: :dashboard

  # Marketing / static
  get "/pricing",      to: "home#pricing",      as: :pricing
  get "/coming_soon",  to: "home#coming_soon",  as: :coming_soon

  # -------------------------
  # Admin Area (authenticated + admin-only)
  # -------------------------
      authenticate :user, lambda { |u| u.respond_to?(:admin?) && u.admin? } do
  # Handy alias so /admin goes to the dashboard
        get "/admin", to: "admin/dashboards#show", as: :admin_root

        namespace :admin do
          # Main Dashboard
          resource :dashboard, only: :show, controller: "dashboards" # admin_dashboard_path

          # Users management
          resources :users, only: [:index, :show] do
            patch :suspend, on: :member  # suspend_admin_user_path(user)
          end

          # Listings moderation
          resources :listings, only: [:index, :edit, :update] do
            patch :approve, on: :member  # approve_admin_listing_path(listing)
            patch :reject,  on: :member  # reject_admin_listing_path(listing)
          end

          # Requests to switch to Estate Agent
          patch "agent_requests/:user_id/approve",
                to: "agent_requests#approve",
                as: :agent_request_approve
          patch "agent_requests/:user_id/decline",
                to: "agent_requests#decline",
                as: :agent_request_decline

          # Support / Tickets
          resources :tickets, only: [:index, :show, :new, :create] do
            patch :close, on: :member     # close_admin_ticket_path(ticket)
          end

          # Billing / Plans
          resource  :billing_settings, only: [:show, :update] # admin_billing_settings_path
          resources :plans                                     # admin_plans_path, etc.

          # Impersonation
          resources :impersonations, only: :create            # admin_impersonations_path
        end
      end
end