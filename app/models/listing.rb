# app/models/listing.rb
class Listing < ApplicationRecord
  belongs_to :user

  # ---- Active Storage attachments ----
  has_one_attached  :banner_image
  has_many_attached :gallery_images
  has_one_attached  :epc

  # ---- Enums ----
  enum property_type: {
    detached: 0, terraced: 1, semi_detached: 2, end_of_terrace: 3,
    bungalow: 4, flat: 5, land: 6, plot: 7, commercial_property: 8
  }

  enum tenure: { freehold: 0, leasehold: 1 }

  enum council_tax_band: {
    unknown: 0, a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, h: 8
  }, _prefix: :council_tax

  # Avoid conflict with ActiveRecord .none scope by prefixing methods
  enum parking: { none: 0, one: 1, two: 2, three_plus: 3 }, _prefix: :parking

  enum status: { draft: 0, published: 1 }

  # ---- Validations ----
  validates :address, presence: true
  validates :property_type, presence: true
  validates :tenure, presence: true

  validates :bedrooms, :bathrooms, presence: true,
           numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :title, presence: true, length: { minimum: 5, maximum: 120 }
  validates :description_raw, presence: true, length: { minimum: 20, maximum: 10_000 }

  validates :size_value, numericality: { greater_than: 0 }, allow_nil: true
  validates :size_unit, inclusion: { in: %w[sq\ ft sqm] }, allow_nil: true

  validate :banner_image_constraints
  validate :gallery_images_constraints
  validate :epc_constraints
  validates :guide_price,
          numericality: { greater_than: 0, allow_nil: true }

  # Sanitize description (if not using ActionText)
  before_validation :sanitize_description!

  # Publishing gate (server-side): ensure required fields present when publishing
  validate :required_fields_for_publish, if: :publishing?

  private

  def publishing?
    # If status changed to published OR currently published and validating
    saved_change_to_status? && published?
  end

  def required_fields_for_publish
    %i[address property_type tenure bedrooms bathrooms title description_raw].each do |attr|
      val = send(attr)
      if val.respond_to?(:blank?) ? val.blank? : val.nil?
        errors.add(attr, "is required to publish")
      end
    end
  end

  # --- File validations ---
  def accept_content_type?(blob, allowed)
    blob&.content_type.present? && allowed.include?(blob.content_type)
  end

  def banner_image_constraints
    return unless banner_image.attached?
    allowed = %w[image/jpeg image/png image/webp]
    unless accept_content_type?(banner_image.blob, allowed)
      errors.add(:banner_image, "must be JPG, PNG, or WEBP")
    end
    if banner_image.blob.byte_size > 10.megabytes
      errors.add(:banner_image, "must be ≤ 10MB")
    end
  end

  def gallery_images_constraints
    return unless gallery_images.attached?
    if gallery_images.attachments.size > 30
      errors.add(:gallery_images, "maximum 30 images")
    end
    allowed = %w[image/jpeg image/png image/webp]
    gallery_images.each do |att|
      unless accept_content_type?(att.blob, allowed)
        errors.add(:gallery_images, "must be JPG, PNG, or WEBP")
      end
      if att.blob.byte_size > 10.megabytes
        errors.add(:gallery_images, "each must be ≤ 10MB")
      end
    end
  end

  def epc_constraints
    return unless epc.attached?
    allowed = %w[application/pdf image/jpeg image/png]
    unless accept_content_type?(epc.blob, allowed)
      errors.add(:epc, "must be PDF, JPG, or PNG")
    end
    if epc.blob.byte_size > 20.megabytes
      errors.add(:epc, "must be ≤ 20MB")
    end
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