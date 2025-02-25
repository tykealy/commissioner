module SpreeCmCommissioner
  class Guest < SpreeCmCommissioner::Base
    include SpreeCmCommissioner::KycBitwise

    delegate :kyc, to: :line_item

    enum gender: { :other => 0, :male => 1, :female => 2 }

    scope :complete, -> { joins(:line_item).merge(Spree::LineItem.complete) }
    scope :unassigned_event, -> { where(event_id: nil) }

    belongs_to :line_item, class_name: 'Spree::LineItem', optional: false
    belongs_to :occupation, class_name: 'Spree::Taxon'
    belongs_to :nationality, class_name: 'Spree::Taxon'

    has_many :state_changes, as: :stateful, class_name: 'Spree::StateChange'

    belongs_to :event, class_name: 'Spree::Taxon'

    has_one :id_card, class_name: 'SpreeCmCommissioner::IdCard', dependent: :destroy
    has_one :check_in, class_name: 'SpreeCmCommissioner::CheckIn'

    preference :telegram_user_id, :string
    preference :telegram_user_verified_at, :string

    before_validation :set_event_id

    self.whitelisted_ransackable_associations = %w[id_card event]
    self.whitelisted_ransackable_attributes = %w[first_name last_name gender occupation_id card_type]

    def self.csv_importable_columns
      column_names.map(&:to_sym)
    end

    # no validation for each field as we allow user to save data to model partially.
    def allowed_checkout?
      kyc_fields.all? { |field| allowed_checkout_for?(field) }
    end

    def allowed_checkout_for?(field) # rubocop:disable Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity
      return (first_name.present? && last_name.present?) if field == :guest_name
      return gender.present? if field == :guest_gender
      return dob.present? if field == :guest_dob
      return occupation.present? || other_occupation.present? if field == :guest_occupation
      return nationality.present? if field == :guest_nationality
      return age.present? if field == :guest_age
      return emergency_contact.present? if field == :guest_emergency_contact
      return other_organization.present? if field == :guest_organization
      return expectation.present? if field == :guest_expectation
      return id_card.present? && id_card.allowed_checkout? if field == :guest_id_card

      false
    end

    def set_event_id
      self.event_id = line_item.associated_event&.id
    end

    def full_name
      [first_name, last_name].compact_blank.join(' ')
    end

    def generate_svg_qr
      qrcode = RQRCode::QRCode.new(qr_data)
      qrcode.as_svg(
        color: '000',
        shape_rendering: 'crispEdges',
        module_size: 5,
        standalone: true,
        use_path: true,
        viewbox: '0 0 20 10'
      )
    end

    def generate_png_qr(size = 120)
      qrcode = RQRCode::QRCode.new(qr_data)
      qrcode.as_png(
        bit_depth: 1,
        border_modules: 1,
        color_mode: ChunkyPNG::COLOR_GRAYSCALE,
        color: 'black',
        file: nil,
        fill: 'white',
        module_px_size: 4,
        resize_exactly_to: false,
        resize_gte_to: false,
        size: size
      )
    end

    def qr_data
      token
    end

    def current_age
      return nil if dob.nil?

      ((Time.zone.now - dob.to_time) / 1.year.seconds).floor
    end
  end
end
