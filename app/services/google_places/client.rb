# app/services/google_places/client.rb
require "net/http"
require "uri"
require "json"

module GooglePlaces
  class Error < StandardError
    attr_reader :http_code, :google_status

    def initialize(message, http_code: nil, google_status: nil)
      super(message)
      @http_code = http_code
      @google_status = google_status
    end
  end

  class Client
    TEXT_SEARCH_URL  = "https://maps.googleapis.com/maps/api/place/textsearch/json".freeze
    DETAILS_URL      = "https://maps.googleapis.com/maps/api/place/details/json".freeze
    PHOTO_BASE_URL   = "https://maps.googleapis.com/maps/api/place/photo".freeze

    MAX_PLACES           = 5
    MAX_PHOTOS_PER_PLACE = 5

    def initialize(api_key: Rails.application.credentials.dig(:google_maps, :api_key))
      @api_key = api_key.to_s
      raise Error.new("Google Places API key missing", http_code: 500) if @api_key.blank?
    end

    # ------------------------------------------------------------------------
    # 1) Light-weight place search (map-friendly)
    # ------------------------------------------------------------------------
    def search_places(query, max_results: MAX_PLACES, type: nil)
      q = query.to_s.strip
      return [] if q.blank?

      uri = URI(TEXT_SEARCH_URL)
      params = {
        key:   @api_key,
        query: q,
        type:  type.presence
      }.compact
      uri.query = URI.encode_www_form(params)

      json = get_json_hash(uri, context: "textsearch")

      google_status = json["status"].to_s
      if google_status != "OK" && google_status != "ZERO_RESULTS"
        msg = json["error_message"].presence || "Google Places text search failed"
        raise Error.new(msg, http_code: 502, google_status: google_status)
      end

      results = Array(json["results"]).first(max_results.to_i)

      results.map do |place|
        # Defensive: ensure each element is a Hash; otherwise skip it.
        next unless place.is_a?(Hash)

        geometry = place["geometry"].is_a?(Hash) ? place["geometry"] : {}
        location = geometry["location"].is_a?(Hash) ? geometry["location"] : {}

        photo0 = Array(place["photos"]).first
        primary_ref =
          photo0.is_a?(Hash) ? photo0["photo_reference"] : nil

        {
          place_id:               place["place_id"],
          name:                   place["name"],
          formatted_address:      place["formatted_address"],
          lat:                    location["lat"],
          lng:                    location["lng"],
          primary_photo_reference: primary_ref
        }
      end.compact
    end

    # ------------------------------------------------------------------------
    # 2) Fetch up to 5 photos for a single place_id
    # ------------------------------------------------------------------------
    def photos_for_place(place_id, max_photos: MAX_PHOTOS_PER_PLACE, max_width: 640)
      pid = place_id.to_s.strip
      return [] if pid.blank?

      uri = URI(DETAILS_URL)
      params = {
        key:      @api_key,
        place_id: pid,
        fields:   "photos"
      }
      uri.query = URI.encode_www_form(params)

      json = get_json_hash(uri, context: "details")

      google_status = json["status"].to_s
      if google_status != "OK"
        msg = json["error_message"].presence || "Google Places details lookup failed"
        # NOT_FOUND / INVALID_REQUEST / REQUEST_DENIED etc.
        raise Error.new(msg, http_code: 502, google_status: google_status)
      end

      result = json["result"].is_a?(Hash) ? json["result"] : {}
      photos = Array(result["photos"]).first(max_photos.to_i)

      photos.map do |photo|
        next unless photo.is_a?(Hash)

        ref = photo["photo_reference"].to_s
        next if ref.blank?

        attributions = Array(photo["html_attributions"]).compact
        attribution_str = attributions.join(", ")

        {
          place_id:          pid,
          photo_reference:   ref,
          photo_url:         build_photo_url(ref, max_width: max_width),
          photo_attribution: attribution_str
        }
      end.compact
    end

    private

    # Ensures we always return a Hash; never a String/Array/etc.
    def get_json_hash(uri, context:)
      res = Net::HTTP.get_response(uri)

      unless res.is_a?(Net::HTTPSuccess)
        # Do not log the full URI because it contains the API key in query params.
        Rails.logger.error("[GooglePlaces::Client] #{context} HTTP #{res.code}")
        raise Error.new("Google Places upstream HTTP #{res.code}", http_code: 502)
      end

      raw = res.body.to_s
      parsed = JSON.parse(raw)

      unless parsed.is_a?(Hash)
        Rails.logger.error("[GooglePlaces::Client] #{context} unexpected JSON root=#{parsed.class}")
        raise Error.new("Google Places returned unexpected payload shape", http_code: 502)
      end

      parsed
    rescue JSON::ParserError => e
      Rails.logger.error("[GooglePlaces::Client] #{context} JSON parse error: #{e.message}")
      raise Error.new("Google Places returned invalid JSON", http_code: 502)
    rescue Error
      raise
    rescue StandardError => e
      Rails.logger.error("[GooglePlaces::Client] #{context} request failed: #{e.class}: #{e.message}")
      raise Error.new("Google Places request failed", http_code: 502)
    end

    def build_photo_url(photo_reference, max_width: 640)
      params = {
        key:            @api_key,
        photoreference: photo_reference,
        maxwidth:       max_width.to_i
      }
      "#{PHOTO_BASE_URL}?#{URI.encode_www_form(params)}"
    end
  end
end
