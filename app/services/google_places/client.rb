# app/services/google_places/client.rb
require "net/http"
require "uri"
require "json"

module GooglePlaces
  class Client
    TEXT_SEARCH_URL  = "https://maps.googleapis.com/maps/api/place/textsearch/json".freeze
    DETAILS_URL      = "https://maps.googleapis.com/maps/api/place/details/json".freeze
    PHOTO_BASE_URL   = "https://maps.googleapis.com/maps/api/place/photo".freeze

    MAX_PLACES           = 5
    MAX_PHOTOS_PER_PLACE = 5

    def initialize(api_key: Rails.application.credentials.dig(:google_maps, :api_key))
      @api_key = api_key
    end

    # ------------------------------------------------------------------------
    # 1) Light-weight place search (map-friendly)
    # ------------------------------------------------------------------------
    def search_places(query, max_results: MAX_PLACES, type: nil)
      return [] if query.blank?

      uri = URI(TEXT_SEARCH_URL)
      params = {
        key:    @api_key,
        query:  query,
        # optional: restrict by type = "cafe", "church", "school", etc.
        type:   type.presence
      }.compact

      uri.query = URI.encode_www_form(params)

      json = get_json(uri)

      Array(json["results"]).first(max_results).map do |place|
        {
          place_id:          place["place_id"],
          name:              place["name"],
          formatted_address: place["formatted_address"],
          lat:               place.dig("geometry", "location", "lat"),
          lng:               place.dig("geometry", "location", "lng"),
          primary_photo_reference: Array(place["photos"]).first&.dig("photo_reference")
        }
      end
    end

    # ------------------------------------------------------------------------
    # 2) Fetch up to 5 photos for a single place_id
    # ------------------------------------------------------------------------
    def photos_for_place(place_id, max_photos: MAX_PHOTOS_PER_PLACE, max_width: 640)
      return [] if place_id.blank?

      # Ask Place Details specifically for the photos array.
      uri = URI(DETAILS_URL)
      params = {
        key:      @api_key,
        place_id: place_id,
        fields:   "photos"
      }
      uri.query = URI.encode_www_form(params)

      json = get_json(uri)
      photos = Array(json.dig("result", "photos")).first(max_photos)

      photos.map do |photo|
        ref = photo["photo_reference"]

        {
          place_id:          place_id,
          photo_reference:   ref,
          photo_url:         build_photo_url(ref, max_width: max_width),
          photo_attribution: Array(photo["html_attributions"]).join(", ")
        }
      end
    end

    private

    def get_json(uri)
      res = Net::HTTP.get_response(uri)
      unless res.is_a?(Net::HTTPSuccess)
        raise "Google Places error #{res.code}: #{res.body}"
      end
      JSON.parse(res.body)
    end

    def build_photo_url(photo_reference, max_width: 640)
      params = {
        key:           @api_key,
        photoreference: photo_reference,
        maxwidth:      max_width
      }
      "#{PHOTO_BASE_URL}?#{URI.encode_www_form(params)}"
    end
  end
end
