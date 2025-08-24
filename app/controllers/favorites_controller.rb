class FavoritesController < ApplicationController
  before_action :authenticate_user!
  respond_to :html, :turbo_stream

  def index
    @listings = Listing
                  .joins(:favorites)
                  .where(favorites: { user_id: current_user.id })
                  .with_attached_banner_image
                  .order(created_at: :desc)
  end

  def create
    listing = Listing.find(params[:listing_id])
    Favorite.find_or_create_by!(user_id: current_user.id, listing_id: listing.id)

    respond_to do |f|
      f.turbo_stream { render_fav_frame_for(listing) }
      f.html         { redirect_back fallback_location: listing_path(listing), notice: "Saved to favorites" }
    end
  end

  def destroy
    fav = Favorite.find_by!(id: params[:id], user_id: current_user.id)
    listing = fav.listing
    fav.destroy

    respond_to do |f|
      f.turbo_stream { render_fav_frame_for(listing) }
      f.html         { redirect_back fallback_location: listing_path(listing), notice: "Removed from favorites" }
    end
  end

  private

  def render_fav_frame_for(listing)
    render turbo_stream: turbo_stream.replace(
      ActionView::RecordIdentifier.dom_id(listing, :fav),
      partial: "favorites/frame",
      locals: { listing: listing }
    )
  end
end