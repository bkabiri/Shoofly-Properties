# app/controllers/seller/listings_controller.rb
module Seller
  class ListingsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_seller!
    before_action :set_listing, only: %i[
      show edit update destroy autosave publish unpublish generate_description
    ]

    rescue_from ActiveRecord::RecordNotFound do
      redirect_to seller_listings_path, alert: "Listing not found."
    end

    rescue_from ActionController::ParameterMissing do |e|
      respond_to do |format|
        format.html { redirect_back fallback_location: seller_listings_path, alert: "Missing parameters: #{e.param}" }
        format.json { render json: { ok: false, error: "Missing parameters: #{e.param}" }, status: :unprocessable_entity }
      end
    end

    def index
      @listings = current_user.listings.order(created_at: :desc)
    end

    def show; end

    def new
      @listing = current_user.listings.new(status: :draft)
    end

    # POST /seller/listings/generate_description  (collection, NEW page)
    # POST /seller/listings/:id/generate_description (member, EDIT/SHOW)
    def generate_description
      listing = @listing || current_user.listings.new(status: :draft)

      attrs = {
        address:       params[:address].presence       || listing.address,
        property_type: params[:property_type].presence || listing.property_type,
        bedrooms:      params[:bedrooms].presence      || listing.bedrooms,
        bathrooms:     params[:bathrooms].presence     || listing.bathrooms
      }

      text = AiDescriptionGenerator.new(listing, attrs).call
      render json: { ok: true, description: text }
    rescue => e
      Rails.logger.error("[AI] description error: #{e.class} #{e.message}")
      render json: { ok: false, error: "Generation failed. Please try again." }, status: :bad_gateway
    end

    def create
      @listing = current_user.listings.new(listing_params_without_status)
      @listing.status ||= :draft

      if @listing.save
        redirect_to seller_listing_path(@listing), notice: "Listing created"
      else
        flash.now[:alert] = "Please fix the errors below"
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      # Do not allow status changes here; handled by publish/unpublish
      if @listing.update(listing_params_without_status)
        redirect_to seller_listing_path(@listing), notice: "Listing updated"
      else
        flash.now[:alert] = "Please fix the errors below"
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @listing.destroy
      redirect_to seller_listings_path, notice: "Listing deleted"
    end

    def publish
      @listing.status = :published
      if @listing.save
        redirect_to seller_listing_path(@listing), notice: "Listing published"
      else
        flash.now[:alert] = "Cannot publish: " + @listing.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    def unpublish
      if @listing.update(status: :draft)
        redirect_to seller_listing_path(@listing), notice: "Listing moved to Draft"
      else
        flash.now[:alert] = "Cannot unpublish: " + @listing.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    # --- Autosave draft (AJAX) ---
    def autosave
      # Force draft regardless of incoming params
      @listing.status = :draft

      if @listing.update(listing_params_without_status)
        render json: { ok: true, updated_at: @listing.updated_at.to_i }
      else
        render json: { ok: false, errors: @listing.errors.to_hash(true) }, status: :unprocessable_entity
      end
    end

    private

    def set_listing
      return unless params[:id].present? # guard for collection routes like generate_description (new)
      @listing = current_user.listings.find(params[:id])
    end

    def ensure_seller!
      unless current_user.respond_to?(:seller?) && current_user.seller?
        redirect_to(root_path, alert: "Seller access only.")
      end
    end

    # Full permitted attributes EXCEPT status (status is controlled by publish/unpublish)
    def listing_params_without_status
      params.require(:listing).permit(
        :address, :place_id,
        :address_line1, :address_line2, :postcode, :city,
        :property_type, :bedrooms, :bathrooms, :size_value, :size_unit,
        :tenure, :council_tax_band, :parking, :garden,
        :title, :description_raw,
        :guide_price,                     # <-- ensure price saves
        :broadband,                       # <-- new fields
        :electricity_supplier,
        :gas_supplier,
        :banner_image, :epc, gallery_images: []
      )
    end

    # Keep this around only if you intentionally allow status somewhere else
    def listing_params
      params.require(:listing).permit(
        :address, :place_id,
        :address_line1, :address_line2, :postcode, :city,
        :property_type, :bedrooms, :bathrooms, :size_value, :size_unit,
        :tenure, :council_tax_band, :parking, :garden,
        :title, :description_raw, :status,
        :guide_price,
        :broadband,
        :electricity_supplier,
        :gas_supplier,
        :banner_image, :epc, gallery_images: []
      )
    end
  end
end