# frozen_string_literal: true
class Users::SessionsController < Devise::SessionsController
  respond_to :html, :turbo_stream

  # POST /users/sign_in
  def create
    self.resource = warden.authenticate(auth_options)

    if resource
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)

      respond_to do |format|
        format.turbo_stream { redirect_to after_sign_in_path_for(resource) }
        format.html         { redirect_to after_sign_in_path_for(resource) }
      end
    else
      # Failed authentication: show an inline flash via Turbo
      # (Use the Devise i18n message so it’s consistent)
      flash.now[:alert] = I18n.t("devise.failure.invalid", authentication_keys: User.authentication_keys.first || "email")

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash"),
                 status: :unauthorized
        end
        format.html { render :new, status: :unauthorized }
      end
    end
  end

  protected

  # Where to go on success
  def after_sign_in_path_for(_resource)
    dashboard_path
  end
end