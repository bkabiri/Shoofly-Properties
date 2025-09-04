# app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @conversation = Conversation.find(params[:conversation_id])
    unless @conversation.participant?(current_user)
      return respond_to do |format|
        format.turbo_stream { head :forbidden }
        format.html         { head :forbidden }
      end
    end

    @message = @conversation.messages.build(message_params.merge(user: current_user))

    if @message.save
      @conversation.touch(:last_message_at)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "messages_list_#{@conversation.id}",
            partial: "messages/message",
            locals: { message: @message, viewer_id: current_user.id }
          )
        end

        # If browser negotiated HTML, still return a turbo-stream so no navigation happens
        format.html do
          render turbo_stream: turbo_stream.append(
                   "messages_list_#{@conversation.id}",
                   partial: "messages/message",
                   locals: { message: @message, viewer_id: current_user.id }
                 ),
                 content_type: "text/vnd.turbo-stream.html"
        end
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