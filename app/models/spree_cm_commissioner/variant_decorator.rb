module SpreeCmCommissioner
  module VariantDecorator
    def self.prepended(base)
      base.include SpreeCmCommissioner::ProductDelegation
      base.include SpreeCmCommissioner::VariantGuestsConcern
      base.include SpreeCmCommissioner::VariantOptionValuesConcern

      base.after_commit :update_vendor_price
      base.after_save   :update_vendor_total_inventory, if: :saved_change_to_permanent_stock?
      base.validate     :validate_option_types

      base.has_many :visible_option_values, lambda {
                                              joins(:option_type).where(spree_option_types: { hidden: false })
                                            }, through: :option_value_variants, source: :option_value

      base.scope :subscribable, -> { active.joins(:product).where(product: { subscribable: true, status: :active }) }
    end

    def delivery_required?
      return true if non_digital_ecommerce?

      delivery_option == 'delivery'
    end

    def non_digital_ecommerce?
      !digital? && ecommerce?
    end

    # override
    def options_text
      @options_text ||= Spree::Variants::VisableOptionsPresenter.new(self).to_sentence
    end

    def selected_option_value_ids
      option_value_variants.pluck(:option_value_id)
    end

    def display_variant
      display_sku = sku.split('-').join(' ')
      display_price = Spree::Money.new(price.to_i, currency: currency).to_s
      "#{display_sku} - #{display_price}"
    end

    private

    def update_vendor_price
      return unless vendor.present? && product&.product_type == vendor&.primary_product_type

      vendor.update(min_price: price) if price < vendor.min_price
      vendor.update(max_price: price) if price > vendor.max_price
    end

    def update_vendor_total_inventory
      SpreeCmCommissioner::VendorJob.perform_later(vendor.id)
    end

    def validate_option_types
      variant = self

      option_values.each do |option_value|
        option_type = option_value.option_type
        next if option_type.nil?

        if variant.is_master? && !option_type.product?
          message = I18n.t('variant.validation.option_type_is_not_product', option_type_name: option_type.name, option_value_name: option_value.name)
          errors.add(:attr_type, message)
        end

        if !variant.is_master? && !option_type.variant?
          message = I18n.t('variant.validation.option_type_is_not_variant', option_type_name: option_type.name, option_value_name: option_value.name)
          errors.add(:attr_type, message)
        end
      end
    end
  end
end

Spree::Variant.prepend(SpreeCmCommissioner::VariantDecorator) unless Spree::Variant.included_modules.include?(SpreeCmCommissioner::VariantDecorator)
