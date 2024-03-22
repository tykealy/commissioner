module Spree
  module Api
    module V2
      module Operator
        class LineItemsController < ::Spree::Api::V2::ResourceController
          before_action :require_spree_current_user

          def index
            render_serialized_payload do
              serialize_collection(paginated_collection)
            end
          end

          def collection
            SpreeCmCommissioner::LineItemSearcherQuery.new(params).call
          end

          def allowed_sort_attributes
            super << :to_date
            super << :from_date
          end

          def resource_serializer
            SpreeCmCommissioner::V2::Operator::LineItemSerializer
          end

          def collection_serializer
            SpreeCmCommissioner::V2::Operator::LineItemSerializer
          end
        end
      end
    end
  end
end
