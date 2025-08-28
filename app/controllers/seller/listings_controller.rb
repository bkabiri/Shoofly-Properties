# app/controllers/seller/listings_controller.rb
module Seller
  class ListingsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_seller!
    before_action :set_listing, only: %i[
      show edit update destroy
      autosave publish unpublish
      feature unfeature bump
      purge_banner purge_epc purge_photo
      generate_description
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

    # GET /seller/listings
    def index
      @listings = current_user.listings
                              .with_attached_banner_image
                              .order(created_at: :desc)
    end

    def show; end

    def new
      @listing = current_user.listings.new(status: :draft)
    end

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

    # POST /seller/listings
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
      if @listing.update(listing_params_without_status)
        if params[:submitted_gallery_keep].present?
          keep_ids = Array(params[:keep_gallery_blob_ids]).map(&:to_s)

          @listing.gallery_images.each do |attachment|
            next if keep_ids.include?(attachment.blob_id.to_s)
            attachment.purge_later
          end
        end

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

    def feature
      ends = [@listing.featured_until, Time.current].compact.max + 7.days
      if @listing.update(featured_until: ends)
        redirect_to seller_listings_path, notice: "Listing featured until #{ends.to_date}."
      else
        redirect_to seller_listings_path, alert: @listing.errors.full_messages.to_sentence
      end
    end

    def unfeature
      if @listing.update(featured_until: nil)
        redirect_to seller_listings_path, notice: "Listing unfeatured."
      else
        redirect_to seller_listings_path, alert: @listing.errors.full_messages.to_sentence
      end
    end

    def bump
      @listing.touch
      redirect_to seller_listings_path, notice: "Listing bumped."
    end

    def purge_banner
      @listing.banner_image.purge_later if @listing.banner_image.attached?
      redirect_back fallback_location: edit_seller_listing_path(@listing), notice: "Banner removed."
    end

    def purge_epc
      @listing.epc.purge_later if @listing.epc.attached?
      redirect_back fallback_location: edit_seller_listing_path(@listing), notice: "EPC removed."
    end

    def purge_photo
      blob_id = params[:blob_id].to_s
      if blob_id.present?
        @listing.gallery_images.each do |att|
          if att.blob_id.to_s == blob_id
            att.purge_later
            break
          end
        end
      end
      redirect_back fallback_location: edit_seller_listing_path(@listing), notice: "Photo removed."
    end

    def autosave
      @listing.status = :draft

      if @listing.update(listing_params_without_status)
        render json: { ok: true, updated_at: @listing.updated_at.to_i }
      else
        render json: { ok: false, errors: @listing.errors.to_hash(true) }, status: :unprocessable_entity
      end
    end

    private

    def set_listing
      return unless params[:id].present?
      @listing =
        current_user.listings.find_by(slug: params[:id]) ||
        current_user.listings.find_by(id: params[:id])   ||
        (raise ActiveRecord::RecordNotFound)
    end

    def ensure_seller!
      unless current_user.respond_to?(:seller?) && current_user.seller?
        redirect_to(root_path, alert: "Seller access only.")
      end
    end

    # Permit everything except status
    def listing_params_without_status
      params.require(:listing).permit(
        :address, :place_id, :latitude, :longitude,
        :address_line1, :address_line2, :postcode, :city,
        :property_type, :bedrooms, :bathrooms, :size_value, :size_unit,
        :tenure, :council_tax_band, :parking, :garden,
        :title, :description_raw,
        :guide_price,
        :broadband,
        :receptions,
        :electricity_supplier,
        :gas_supplier,
        :banner_image, :epc,
        gallery_images: []
      )
    end

    # Full list (if you ever need status)
    def listing_params
      params.require(:listing).permit(
        :address, :place_id, :latitude, :longitude,
        :address_line1, :address_line2, :postcode, :city,
        :property_type, :bedrooms, :bathrooms, :size_value, :size_unit,
        :tenure, :council_tax_band, :parking, :garden,
        :title, :description_raw, :status,
        :guide_price,
        :broadband,
        :receptions,
        :electricity_supplier,
        :gas_supplier,
        :banner_image, :epc,
        gallery_images: []
      )
    end
  end
end