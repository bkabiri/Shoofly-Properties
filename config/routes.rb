Rails.application.routes.draw do
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
          post  :generate_description     # POST /seller/listings/:id/generate_description
          patch :autosave                 # PATCH /seller/listings/:id/autosave
          patch :publish                  # PATCH /seller/listings/:id/publish
          patch :unpublish
          delete :purge_banner
          delete :purge_epc
          delete :purge_photo              # PATCH /seller/listings/:id/unpublish
        end
      end
    end
  end

  # Nice alias (short URL) – public helper to seller dashboard
  get "/dashboard", to: "seller/dashboards#show", as: :dashboard
end