# app/controllers/api/v1/places_controller.rb
module Api
  module V1
    class PlacesController < ApplicationController
      before_action :authenticate_amigo!

      # GET /api/v1/places/search?q=...&type=cafe
      def search
        query = params[:q].to_s.strip
        type  = params[:type].presence # e.g. "cafe", "church", etc.

        if query.blank?
          render json: [], status: :ok
          return
        end

        client  = GooglePlaces::Client.new
        results = client.search_places(query, max_results: 5, type: type)

        render json: results, status: :ok
      rescue StandardError => e
        Rails.logger.error("[PlacesController#search] #{e.class}: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n")) if Rails.env.development?
        render json: { error: "Places lookup failed" }, status: :service_unavailable
      end

      # GET /api/v1/places/:id/photos
      def photos
        place_id = params[:id].to_s
        return render json: [], status: :ok if place_id.blank?

        photos = GooglePlaces::FetchPhotosForPlace.call(place_id)
        render json: photos, status: :ok
      rescue StandardError => e
        Rails.logger.error("[PlacesController#photos] #{e.class}: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n")) if Rails.env.development?
        render json: { error: "Photo lookup failed" }, status: :service_unavailable
      end
    end
  end
end
