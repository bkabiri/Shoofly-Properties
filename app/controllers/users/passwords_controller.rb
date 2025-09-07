# app/controllers/users/passwords_controller.rb
class Users::PasswordsController < Devise::PasswordsController
  respond_to :html, :turbo_stream

  # POST /users/password
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      set_flash_message!(:notice, :send_instructions)
      respond_to do |format|
        format.html         { redirect_to after_sending_reset_password_instructions_path_for(resource_name), status: :see_other }
        format.turbo_stream { render "devise/shared/flash_stream" }
      end
    else
      # Keep errors and re-render the form for both formats
      respond_to do |format|
        format.html         { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end
end