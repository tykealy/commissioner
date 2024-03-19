module Spree
  module Events
    class GuestsController < Spree::Events::BaseController
      helper SpreeCmCommissioner::Admin::GuestHelper

      def collection_url
        event_guests_url
      end

      def model_class
        SpreeCmCommissioner::Guest
      end

      def index
        file_name = Rails.root.join('tmp', csv_name)

        respond_with(collection) do |format|
          format.csv do
            SpreeCmCommissioner::GenerateGuestsCsv.call(
              collection: collection,
              file_name: file_name
            )

            send_file file_name
          end
        end
      end

      def edit
        @guest = SpreeCmCommissioner::Guest.find(params[:id])
        @event = @guest.event
      end

      private

      def csv_name
        @csv_name ||= "guests-data-#{current_event.name.downcase.gsub(' ', '-')}-#{Time.current.to_i}.csv"
      end

      def permitted_resource_params
        params.required(:spree_cm_commissioner_guest).permit(:entry_type)
      end

      def collection
        scope = model_class.where(event_id: current_event.id)

        @search = scope.ransack(params[:q])
        @collection = @search.result
                             .includes(:id_card)
                             .page(params[:page])
                             .per(params[:per_page])
      end
    end
  end
end
