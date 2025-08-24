# app/models/listing.rb
class Listing < ApplicationRecord
  belongs_to :user

  # ---- Attachments ----
  has_one_attached  :banner_image
  has_many_attached :gallery_images
  has_many :favorites, dependent: :destroy
  has_many :fans, through: :favorites, source: :user
  has_one_attached  :epc

  # ---- Enums ----
  enum property_type: {
    detached: 0, terraced: 1, semi_detached: 2, end_of_terrace: 3,
    bungalow: 4, flat: 5, land: 6, plot: 7, commercial_property: 8
  }
  enum tenure: { freehold: 0, leasehold: 1 }
  enum council_tax_band: { unknown: 0, a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, h: 8 }, _prefix: :council_tax
  enum parking: { none: 0, one: 1, two: 2, three_plus: 3 }, _prefix: :parking
  enum status: { draft: 0, published: 1 }

  # New: sale lifecycle (powers “Include Under Offer, Sold STC”)
  # available → under_offer → sold_stc → sold (for example)
  enum sale_status: { available: 0, under_offer: 1, sold_stc: 2, sold: 3 }, _prefix: :sale

  # ---- Scopes ----
  scope :published_only, -> { where(status: :published) }
  scope :with_hero,      -> { with_attached_banner_image }
  scope :priced_min,     ->(v) { where("guide_price >= ?", v) if v.present? }
  scope :priced_max,     ->(v) { where("guide_price <= ?", v) if v.present? }
  scope :beds_min,       ->(v) { where("bedrooms >= ?", v) if v.present? }
  scope :beds_max,       ->(v) { where("bedrooms <= ?", v) if v.present? }
  scope :added_since,    ->(days) { where("created_at >= ?", days.to_i.days.ago) if days.present? && days.to_i.positive? }

  # When you *don’t* tick “include under offer”, show only fully available stock
  scope :market_available_only, -> { where(sale_status: sale_statuses[:available]) }
  # When you *do* tick it, include under_offer + sold_stc in the feed
  scope :market_including_uo_stc, -> { where(sale_status: sale_statuses.values_at(:available, :under_offer, :sold_stc)) }

  # ---- Validations ----
  validates :address, :property_type, :tenure, presence: true
  validates :bedrooms, :bathrooms, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :title, presence: true, length: { minimum: 5, maximum: 120 }
  validates :description_raw, presence: true, length: { minimum: 20, maximum: 10_000 }
  validates :size_value, numericality: { greater_than: 0 }, allow_nil: true
  validates :size_unit, inclusion: { in: %w[sq\ ft sqm] }, allow_nil: true
  validates :guide_price, numericality: { greater_than: 0 }, allow_nil: true
  validates :slug, uniqueness: true, allow_nil: true

  # ---- Slug + content safety ----
  before_validation :ensure_slug!
  before_validation :sanitize_description!

  # Publishing gate
  validate :required_fields_for_publish, if: :publishing?

  # ---- Public helpers for UI ----
  def to_param
    slug.presence || id.to_s
  end

  # Nice select helpers for the filters (optional)
  def self.property_type_options
    property_types.keys.map { |k| [k.humanize, k] }
  end

  def self.bedroom_options(max = 10)
    [["No min", ""], *1.upto(max).map { |n| ["#{n}+", n] }]
  end

  def self.price_options(steps = [100_000, 200_000, 300_000, 400_000, 500_000, 750_000, 1_000_000, 1_500_000, 2_000_000])
    [["No min / No max", ""], *steps.map { |p| ["£#{p.to_s(:delimited, delimiter: ',')}", p] }]
  end

  private

  def publishing?
    saved_change_to_status? && published?
  end

  def required_fields_for_publish
    %i[address property_type tenure bedrooms bathrooms title description_raw].each do |attr|
      val = send(attr)
      errors.add(attr, "is required to publish") if val.blank?
    end
  end

  # ---------- Slug helpers ----------
  def ensure_slug!
    return if slug.present?

    base = build_slug_base
    candidate = base.presence || id&.to_s
    candidate = "listing-#{SecureRandom.hex(3)}" if candidate.blank?

    # ensure uniqueness
    n = 1
    while Listing.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base}-#{n}"
      n += 1
    end

    self.slug = candidate
  end

  def build_slug_base
    parts = []
    parts << address.to_s.parameterize if address.present?
    parts << "#{bedrooms}-bed" if bedrooms.present? && bedrooms.to_i > 0
    parts << property_type.to_s.dasherize if property_type.present?
    parts.join("-").squeeze("-")
  end

  # ---------- Files ----------
  def accept_content_type?(blob, allowed)
    blob&.content_type.present? && allowed.include?(blob.content_type)
  end

  def banner_image_constraints
    return unless banner_image.attached?
    allowed = %w[image/jpeg image/png image/webp]
    errors.add(:banner_image, "must be JPG, PNG, or WEBP") unless accept_content_type?(banner_image.blob, allowed)
    errors.add(:banner_image, "must be ≤ 10MB") if banner_image.blob.byte_size > 10.megabytes
  end

  def gallery_images_constraints
    return unless gallery_images.attached?
    errors.add(:gallery_images, "maximum 30 images") if gallery_images.attachments.size > 30
    allowed = %w[image/jpeg image/png image/webp]
    gallery_images.each do |att|
      errors.add(:gallery_images, "must be JPG, PNG, or WEBP") unless accept_content_type?(att.blob, allowed)
      errors.add(:gallery_images, "each must be ≤ 10MB") if att.blob.byte_size > 10.megabytes
    end
  end

  def epc_constraints
    return unless epc.attached?
    allowed = %w[application/pdf image/jpeg image/png]
    errors.add(:epc, "must be PDF, JPG, or PNG") unless accept_content_type?(epc.blob, allowed)
    errors.add(:epc, "must be ≤ 20MB") if epc.blob.byte_size > 20.megabytes
  end

  def sanitize_description!
    return if description_raw.blank?
    self.description_raw = ActionController::Base.helpers.sanitize(
      description_raw,
      tags: %w[p br strong em ul ol li a h3 h4 h5 blockquote],
      attributes: %w[href title rel target]
    )
  end
end