# app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @conversation = Conversation.find(params[:conversation_id])
    return head :forbidden unless @conversation.participant?(current_user)

    @message = @conversation.messages.build(message_params.merge(user: current_user))

    if @message.save
      @conversation.touch(:last_message_at)
      # ✔ Do not append here — the model broadcast handles *both* viewers.
      respond_to do |format|
        format.turbo_stream { head :no_content }   # Turbo request
        format.html         { head :no_content }   # any fallback
      end
    else
      respond_to do |format|
        format.turbo_stream { head :unprocessable_entity }
        format.html         { head :unprocessable_entity }
      end
    end
  end


  private

  def message_params
    params.require(:message).permit(:body)
  end
end