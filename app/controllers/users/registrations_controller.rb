# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters

  # Let users update profile without entering current password
  protected
  def update_resource(resource, params)
    resource.update_without_password(params)
  end

  def after_update_path_for(resource)
    # Where to go after successful save
    dashboard_path # or edit_user_registration_path
  end

  def configure_permitted_parameters
    # Add whatever extra fields you allow
    extra = [
      :full_name, :mobile_phone,
      :estate_agent_name,
      :office_address_line1, :office_address_line2, :office_city, :office_county, :office_postcode,
      :landline_phone
      # :logo # (only if you allow avatar/logo here via Devise form)
    ]

    devise_parameter_sanitizer.permit(:sign_up,       keys: extra)
    devise_parameter_sanitizer.permit(:account_update, keys: extra)
  end
end