module SpreeCmCommissioner
  module TaxonomyDecorator
    def self.prepended(base)
      base.enum kind: { category: 0, cms: 1, event: 2 }
    end
  end
end

unless Spree::Taxonomy.included_modules.include?(SpreeCmCommissioner::TaxonomyDecorator)
  Spree::Taxonomy.prepend(SpreeCmCommissioner::TaxonomyDecorator)
end
