# app/controllers/listings_controller.rb
class ListingsController < ApplicationController
  before_action :normalize_index_params, only: :index

  # Change this to 0.25 if you prefer a tighter “area only”
  AREA_ONLY_MILES = 0.5

  def index
    scope = Listing.published_only
                   .with_attached_banner_image
                   .order(created_at: :desc)

    # ------- location / radius (Google Places or fallback geocode) -------
    origin        = nil
    radius_raw    = @filters[:radius] # "0","0.25","1",...,"national", or nil
    use_national  = radius_raw.to_s == "national"
    numeric_radius = radius_raw.to_s.match?(/\A\d+(\.\d+)?\z/) ? radius_raw.to_f : nil

    # Prefer Places lat/lng, else best-effort geocode q (if Geocoder present)
    if params[:lat].present? && params[:lng].present?
      origin = [params[:lat].to_f, params[:lng].to_f]
    elsif @filters[:q].present? && defined?(Geocoder)
      if (geo = Geocoder.search(@filters[:q]).first)&.coordinates
        origin = geo.coordinates # [lat, lng]
      end
    end

    # Effective radius:
    # - national: nil (no radius filter)
    # - numeric > 0: use it
    # - "0" (This area only): use AREA_ONLY_MILES
    effective_miles =
      if use_national
        nil
      elsif numeric_radius && numeric_radius > 0
        numeric_radius
      elsif radius_raw.to_s == "0"
        AREA_ONLY_MILES
      end

    if origin.present? && Listing.respond_to?(:near) && effective_miles
      scope = scope.near(origin, effective_miles * 1.60934, order: :distance) # distance_in_km available
    end

    # ------- keyword search (only if no successful location geocode) -------
    if @filters[:q].present? && origin.blank?
      like = "%#{@filters[:q]}%"
      scope = scope.where("title ILIKE :like OR address ILIKE :like", like: like)
    end

    # ------- property types (multi-select) -------
    scope = scope.where(property_type: @filters[:property_types]) if @filters[:property_types].present?

    # ------- price range -------
    scope = scope.where("guide_price >= ?", @filters[:min_price]) if @filters[:min_price]
    scope = scope.where("guide_price <= ?", @filters[:max_price]) if @filters[:max_price]

    # ------- bedrooms -------
    scope = scope.where("bedrooms >= ?", @filters[:min_beds]) if @filters[:min_beds]
    scope = scope.where("bedrooms <= ?", @filters[:max_beds]) if @filters[:max_beds]

    # ------- added since (days) -------
    if @filters[:added_since]&.positive?
      scope = scope.where("created_at >= ?", @filters[:added_since].days.ago)
    end

    # ------- include under-offer / sold-stc -------
    if Listing.respond_to?(:sale_statuses) && Listing.column_names.include?("sale_status")
      if @filters[:include_under_offer]
        allowed = Listing.sale_statuses.values_at(:available, :under_offer, :sold_stc)
        scope = scope.where(sale_status: allowed)
      else
        scope = scope.where(sale_status: Listing.sale_statuses[:available])
      end
    end

    # ------- sorting -------
    @sort = permitted_sort(@filters[:sort])
    scope =
      case @sort
      when "price_asc"  then order_price(scope, direction: :asc)
      when "price_desc" then order_price(scope, direction: :desc)
      when "beds_desc"  then scope.order(bedrooms: :desc, created_at: :desc)
      when "distance"   then origin.present? ? scope : scope.order(created_at: :desc) # .near already ordered
      else                    scope.order(created_at: :desc) # newest
      end

    # ------- pagination (Kaminari) -------
    @listings = defined?(Kaminari) ? scope.page(params[:page]).per(12) : scope

    # Expose for the view (map pins, chips, etc.)
    @origin            = origin
    @radius_miles      = effective_miles
    @radius_km         = effective_miles ? effective_miles * 1.60934 : nil
    @place_id          = params[:place_id].presence
    @formatted_address = params[:formatted_address].presence
  end

  def show
    return redirect_to listings_path, status: :moved_permanently if params[:id].to_s == "index"

    @listing = Listing.published_only.with_attached_banner_image.find_by(slug: params[:id])
    if @listing.nil? && numeric?(params[:id])
      rec = Listing.published_only.with_attached_banner_image.find_by(id: params[:id].to_i)
      if rec
        canonical = listing_path(rec)
        return redirect_to(canonical, status: :moved_permanently) if request.path != canonical
        @listing = rec
      end
    end

    redirect_to listings_path, alert: "Listing not found." unless @listing
  end

  private

  # Normalize and whitelist incoming filter params into @filters
  def normalize_index_params
    allowed_pts  = Listing.property_types.keys
    selected_pts = Array(params[:property_type]).reject(&:blank?) & allowed_pts

    @filters = {
      q:                   params[:q].to_s.strip.presence,
      property_types:      selected_pts,                    # array
      min_price:           to_i_or_nil(params[:min_price]),
      max_price:           to_i_or_nil(params[:max_price]),
      min_beds:            to_i_or_nil(params[:min_beds]),
      max_beds:            to_i_or_nil(params[:max_beds]),
      added_since:         to_i_or_nil(params[:added_since]),
      include_under_offer: params[:include_under_offer].present?,
      sort:                params[:sort].presence,

      # Location fields from the view
      radius:              params[:radius].presence,        # "0","0.25","1",...,"national"
      place_id:            params[:place_id].presence,
      lat:                 params[:lat].presence,
      lng:                 params[:lng].presence,
      formatted_address:   params[:formatted_address].presence
    }
  end

  def to_i_or_nil(val)
    return nil if val.blank?
    Integer(val) rescue nil
  end

  def numeric?(val)
    Integer(val)
    true
  rescue ArgumentError, TypeError
    false
  end

  def permitted_sort(raw)
    %w[newest price_asc price_desc beds_desc distance].include?(raw) ? raw : "newest"
  end

  # Price ordering with NULLS LAST fallback
  def order_price(scope, direction:)
    dir_sql = direction == :asc ? "ASC" : "DESC"
    adapter = ActiveRecord::Base.connection.adapter_name.downcase

    case adapter
    when /postgres/
      scope.order(Arel.sql("guide_price IS NULL, guide_price #{dir_sql}, created_at DESC"))
    else
      scope.order(Arel.sql("CASE WHEN guide_price IS NULL THEN 1 ELSE 0 END ASC, guide_price #{dir_sql}, created_at DESC"))
    end
  end
end