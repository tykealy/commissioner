module SpreeCmCommissioner
  module ProductDecorator
    def self.prepended(base) # rubocop:disable Metrics/AbcSize
      base.include SpreeCmCommissioner::ProductType
      base.include SpreeCmCommissioner::KycBitwise

      base.has_many :variant_kind_option_types, -> { where(kind: :variant).order(:position) },
                    through: :product_option_types, source: :option_type

      base.has_many :product_kind_option_types, -> { where(kind: :product).order(:position) },
                    through: :product_option_types, source: :option_type

      base.has_many :promoted_option_types, -> { where(promoted: true).order(:position) },
                    through: :product_option_types, source: :option_type

      base.has_many :option_values, through: :option_types
      base.has_many :prices_including_master, lambda {
                                                order('spree_variants.position, spree_variants.id, currency')
                                              }, source: :prices, through: :variants_including_master

      base.has_many :homepage_section_relatables,
                    class_name: 'SpreeCmCommissioner::HomepageSectionRelatable',
                    dependent: :destroy, as: :relatable

      # after finish purchase an order, user must complete these steps
      base.has_many :product_completion_steps, class_name: 'SpreeCmCommissioner::ProductCompletionStep', dependent: :destroy

      base.has_one :default_state, through: :vendor

      base.has_many :complete_line_items, through: :classifications, source: :line_items

      base.scope :min_price, lambda { |vendor|
        joins(:prices_including_master)
          .where(vendor_id: vendor.id, product_type: vendor.primary_product_type)
          .minimum('spree_prices.price').to_f
      }

      base.scope :max_price, lambda { |vendor|
        joins(:prices_including_master)
          .where(vendor_id: vendor.id, product_type: vendor.primary_product_type)
          .maximum('spree_prices.price').to_f
      }
      base.scope :subscribable, -> { where(subscribable: 1) }

      base.validate :validate_event_taxons, if: -> { taxons.event.present? }

      base.whitelisted_ransackable_attributes = %w[description name slug discontinue_on status vendor_id]
    end

    def validate_event_taxons
      errors.add(:taxons, 'Event Taxon can\'t not be more than 1') if taxons.event.size > 1
      errors.add(:taxons, 'Must add event date to taxon') if taxons.event.first.from_date.nil? || taxons.event.first.to_date.nil?
    end

    def associated_event
      taxons.event.first&.parent
    end
  end
end

Spree::Product.prepend(SpreeCmCommissioner::ProductDecorator) unless Spree::Product.included_modules.include?(SpreeCmCommissioner::ProductDecorator)
