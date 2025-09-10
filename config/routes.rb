# config/routes.rb
require "sidekiq/web"
Rails.application.routes.draw do
  # -------------------------
  # Public Listings
  # -------------------------
  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end
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
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions:      "users/sessions",
    passwords:     "users/passwords"
  }
  #root to: "home#index"
  root "home#coming_soon"

  # -------------------------
  # Checkout
  # -------------------------
  resources :checkout, only: [] do
    collection do
      post :sessions
      get  :success
      get  :cancel
    end
  end
  post "/checkout_sessions", to: "checkout#sessions"

  # -------------------------
  # Authenticated Seller Area
  # -------------------------
  authenticate :user do
    namespace :seller do
      resource :dashboard, only: :show, controller: "dashboards"

      resource :account, only: :show, controller: "accounts" do
        patch :switch_to_estate_agent
        patch :switch_to_private_seller
        patch :update_office_details
      end

      resources :team_members, only: [:index, :create, :update, :destroy], controller: "team_members"

      resources :invites, only: [:index, :create, :destroy], controller: "invites" do
        post :resend, on: :member
      end

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
  get "/pricing",     to: "home#pricing",     as: :pricing
  get "/coming_soon", to: "home#coming_soon", as: :coming_soon

  # -------------------------
  # Messaging (authenticated)
  # -------------------------
  authenticate :user do
  # Conversations around a listing (+ typing pings)
  resources :conversations, only: [:show, :create, :destroy] do
    post :typing, on: :member
  end

  # Message create (both helpers kept)
  resources :messages, only: [:create, :destroy]
  post "/conversations/:conversation_id/messages",
       to: "messages#create",
       as: :conversation_messages
end

  
  
  mount ActionCable.server => "/cable"
  # -------------------------
  # Admin Area (authenticated + admin-only)
  # -------------------------
  authenticate :user, lambda { |u| u.respond_to?(:admin?) && u.admin? } do
    get "/admin", to: "admin/dashboards#show", as: :admin_root

    namespace :admin do
      resource :dashboard, only: :show, controller: "dashboards"
      resources :impersonations, only: [:create, :destroy]
      resources :promotion_codes, only: [:index, :create, :update, :destroy]
      resources :users, only: [:index, :show, :edit, :update, :destroy] do
        member do
          patch :block   # -> Admin::UsersController#block
          # (optionally) patch :unblock
        end
      end

      resources :listings, only: [:index, :edit, :update] do
        patch :approve, on: :member
        patch :reject,  on: :member
      end

      patch "agent_requests/:user_id/approve",
            to: "agent_requests#approve",
            as: :agent_request_approve
      patch "agent_requests/:user_id/decline",
            to: "agent_requests#decline",
            as: :agent_request_decline

      resources :tickets, only: [:index, :show, :new, :create, :update] do
        patch :resolve, on: :member
        patch :close,   on: :member
        resources :ticket_messages, only: [:create]
      end

      resource  :billing_settings, only: [:show, :update]
      resources :plans

      resources :impersonations, only: :create
    end
  end
end