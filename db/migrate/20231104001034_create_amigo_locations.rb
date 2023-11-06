class CreateAmigoLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :amigo_locations do |t|
      t.references :amigo, null: false, foreign_key: true
      t.string :address, limit: 256
      t.string :address_type, limit: 12
      t.string :floor, limit: 10
      t.string :building, limit: 16
      t.string :street_predirection, limit: 16
      t.string :street_number, limit: 30
      t.string :street_name, limit: 64
      t.string :street_postdirection, limit: 16
      t.string :street_suffix, limit: 16
      t.string :apartment_number, limit: 32
      t.string :city, limit: 64
      t.string :county, limit: 64
      t.string :state_abbreviation, limit: 2
      t.string :country_code, limit: 5
      t.string :postal_code, limit: 12
      t.string :plus4_code, limit: 4
      t.decimal :latitude, precision: 9, scale: 6
      t.decimal :longitude, precision: 9, scale: 6
      t.string :time_zone, limit: 48
      t.string :congressional_district, limit: 2

      t.timestamps
    end
  end
end
