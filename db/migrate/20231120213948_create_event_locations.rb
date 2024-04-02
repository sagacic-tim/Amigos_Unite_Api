class CreateEventLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :event_locations do |t|
      # t.references :amigo, null: false, foreign_key: true
      t.string  :business_name, limit: 64
      t.string  :business_phone, limit: 15
      t.string  :address, limit: 256
      t.string  :floor, limit: 10
      t.string  :street_number, limit: 32
      t.string  :street_name, limit: 96
      t.string  :room_no, limit: 32
      t.string  :apartment_suite_number, limit: 32
      t.string  :city_sublocality, limit: 96
      t.string  :city, limit: 64
      t.string  :state_province_subdivision, limit: 96
      t.string  :state_province, limit: 32
      t.string  :state_province_short, limit: 8
      t.string  :country, limit: 32
      t.string  :country_short, limit: 3
      t.string  :postal_code, limit: 12
      t.string  :postal_code_suffix, limit: 6
      t.string  :post_box, limit: 12
      t.float   :latitude
      t.float   :longitude
      t.string  :time_zone, limit: 48

      t.timestamps
    end
  end
end
