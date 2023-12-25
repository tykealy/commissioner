module Spree
  module Api
    module V2
      module Storefront
        class GuestLineItemsController < Spree::Api::V2::ResourceController
          include OrderConcern

          before_action :ensure_order

          # override
          def model_class
            Spree::LineItem
          end

          # override
          def resource_serializer
            SpreeCmCommissioner::V2::Storefront::GuestLineItemSerializer
          end

          # override
          def index
            guest_line_items = spree_current_order.line_items

            render_serialized_payload { serialize_resource(guest_line_items) }
          end
        end
      end
    end
  end
end
