class ApplicationController < ActionController::Base
  
  # Where to send users after sign up / sign in
  def after_sign_up_path_for(resource)
    root_path # or dashboard_path if you have one
  end

  def after_sign_in_path_for(resource)
    root_path # or dashboard_path
  end
   
end