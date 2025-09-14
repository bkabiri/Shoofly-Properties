# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters

  protected

  # Let users update profile without entering current password
  def update_resource(resource, params)
    # Strip Devise's virtual key so AR doesn't choke
    params.delete(:current_password)

    # If password not being changed, remove these so validations don't run
    if params[:password].blank?
      params.delete(:password)
      params.delete(:password_confirmation)
    end

    resource.update_without_password(params)
  end

  def after_sign_up_path_for(resource)
  confirm_email_path
  end


  def configure_permitted_parameters
    extra = [
      :full_name, :mobile_phone,
      :estate_agent_name,
      :office_address_line1, :office_address_line2, :office_city, :office_county, :office_postcode,
      :landline_phone
      # :logo
    ]

    devise_parameter_sanitizer.permit(:sign_up,        keys: extra)
    devise_parameter_sanitizer.permit(:account_update, keys: extra + [:password, :password_confirmation, :current_password])
  end
end