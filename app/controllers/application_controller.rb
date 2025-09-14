class ApplicationController < ActionController::Base
  
  # Where to send users after sign up / sign in

  private
  def after_sign_in_path_for(resource)
    # Prefer stored location if Devise saved one (e.g., you were bounced)
    stored_location_for(resource) ||
      (Rails.env.development? ? listings_path : root_path)
  end
end