# config/routes.rb
Rails.application.routes.draw do
  # Public listings
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

  # Devise + home
  get "home/index"

  devise_for :users
  root to: "home#index"

  # -------------------------
  # Authenticated Seller area
  # -------------------------
  authenticate :user do
    namespace :seller do
      # Dashboard (controller is Seller::DashboardsController)
      resource :dashboard, only: :show, controller: "dashboards"

      # Account type switching + office details (controller: Seller::AccountsController)
      resource :account, only: :show, controller: "accounts" do
        patch :switch_to_estate_agent
        patch :switch_to_private_seller
        patch :update_office_details
      end

      # Team management (controller: Seller::TeamMembersController)
      resources :team_members, only: [:index, :create, :update, :destroy], controller: "team_members"

      # Invite management (controller: Seller::InvitesController)
      resources :invites, only: [:index, :create, :destroy], controller: "invites" do
        post :resend, on: :member
      end

      # Listings (with feature/unfeature/bump and assets purging)
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

  # Nice alias for the dashboard
  get "/dashboard", to: "seller/dashboards#show", as: :dashboard
  get "/pricing", to: "home#pricing", as: :pricing
end