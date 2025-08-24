Rails.application.routes.draw do
  resources :listings, only: [:index, :show] do
  post "favorite",   to: "favorites#create"
  delete "unfavorite", to: "favorites#destroy"
  end
  authenticate :user do
  resources :favorites, only: %i[index create destroy]
  end

  get "/saved", to: "favorites#index", as: :saved_properties
  # catch old/bad links like /listings/index
  get "/listings/index", to: redirect("/listings")
  get "home/index"
  devise_for :users

  root to: "home#index"

  # Authenticated seller area
  authenticate :user do
    namespace :seller do
      resource :dashboard, only: :show   # /seller/dashboard

      resources :listings do
        # For the NEW page (no ID yet)
        collection do
          post :generate_description      # POST /seller/listings/generate_description
        end

        # For EDIT/SHOW pages (with ID)
        member do
          post  :generate_description
          patch :autosave
          patch :publish
          patch :unpublish
          patch :feature        # NEW  -> /seller/listings/:id/feature
          patch :unfeature      # NEW  -> /seller/listings/:id/unfeature
          patch :bump           # NEW  -> /seller/listings/:id/bump
          delete :purge_banner
          delete :purge_epc
          delete :purge_photo
        end
      end
    end
  end

  # Nice alias (short URL) – public helper to seller dashboard
  get "/dashboard", to: "seller/dashboards#show", as: :dashboard
end