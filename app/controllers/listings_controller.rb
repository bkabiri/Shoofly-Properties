# app/controllers/listings_controller.rb
class ListingsController < ApplicationController
  before_action :normalize_index_params, only: :index

  def index
    scope = Listing.published_only
                   .with_attached_banner_image
                   .order(created_at: :desc)

    # --- keyword search ---
    if @filters[:q].present?
      like = "%#{@filters[:q]}%"
      scope = scope.where("title ILIKE :like OR address ILIKE :like", like: like)
    end

    # --- property types (multi-select) ---
    if @filters[:property_types].present?
      scope = scope.where(property_type: @filters[:property_types])
    end

    # --- price range ---
    scope = scope.where("guide_price >= ?", @filters[:min_price]) if @filters[:min_price]
    scope = scope.where("guide_price <= ?", @filters[:max_price]) if @filters[:max_price]

    # --- bedrooms ---
    scope = scope.where("bedrooms >= ?", @filters[:min_beds]) if @filters[:min_beds]
    scope = scope.where("bedrooms <= ?", @filters[:max_beds]) if @filters[:max_beds]

    # --- added since (days) ---
    if @filters[:added_since]&.positive?
      scope = scope.where("created_at >= ?", @filters[:added_since].days.ago)
    end

    # --- include under-offer / sold-stc (NO-OP unless sale_status enum exists) ---
    if Listing.respond_to?(:sale_statuses) && Listing.column_names.include?("sale_status")
      if @filters[:include_under_offer]
        allowed = Listing.sale_statuses.values_at(:available, :under_offer, :sold_stc)
        scope = scope.where(sale_status: allowed)
      else
        scope = scope.where(sale_status: Listing.sale_statuses[:available])
      end
    end

    # --- sorting ---
    @sort = permitted_sort(@filters[:sort])
    scope =
      case @sort
      when "price_asc"  then order_price(scope, direction: :asc)
      when "price_desc" then order_price(scope, direction: :desc)
      when "beds_desc"  then scope.order(bedrooms: :desc, created_at: :desc)
      else                    scope.order(created_at: :desc) # newest
      end

    # --- pagination (Kaminari) ---
    @listings = defined?(Kaminari) ? scope.page(params[:page]).per(12) : scope
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
    allowed_pts = Listing.property_types.keys
    selected_pts = Array(params[:property_type]).reject(&:blank?) & allowed_pts

    @filters = {
      q: params[:q].to_s.strip.presence,
      property_types: selected_pts,                                   # <-- array
      min_price: to_i_or_nil(params[:min_price]),
      max_price: to_i_or_nil(params[:max_price]),
      min_beds: to_i_or_nil(params[:min_beds]),
      max_beds: to_i_or_nil(params[:max_beds]),
      added_since: to_i_or_nil(params[:added_since]),
      include_under_offer: params[:include_under_offer].present?,
      sort: params[:sort].presence
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
    %w[newest price_asc price_desc beds_desc].include?(raw) ? raw : "newest"
  end

  # Price ordering with NULLS LAST fallback for adapters that don’t support it
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