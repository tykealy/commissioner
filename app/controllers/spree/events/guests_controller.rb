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
        respond_with(collection) do |format|
          format.csv do
            generate_csv

            if Sidekiq::Status.complete?(@job_status)
              download_csv
            else
              flash[:notice] = 'The CSV file is being generated. Please wait a moment and try again.'
              redirect_to collection_url
            end
          end
        end
      end

      def generate_csv
        guest_ids = collection.pluck(:id)
        @generate_guest_csv_job_id = SpreeCmCommissioner::GenerateGuestsCsvJob.perform_async(guest_ids, csv_file_path)
        session[:generate_guest_csv_job_id] = @generate_guest_csv_job_id
        @job_status = Sidekiq::Status.status(@generate_guest_csv_job_id)
      end

      def download_csv
        @generate_guest_csv_job_id = session[:generate_guest_csv_job_id]
        if Sidekiq::Status.complete? @generate_guest_csv_job_id
          send_file csv_file_path
        else
          flash[:alert] = 'The CSV file is in progress. Please wait a moment and try again.'
          redirect_to collection_url
        end
      end

      def edit
        @guest = SpreeCmCommissioner::Guest.find(params[:id])
        @event = @guest.event
      end

      private

      def csv_file_path
        @csv_file_path ||= Rails.root.join('tmp', csv_name)
      end

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
