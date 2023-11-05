class CreateAmigoLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :amigo_locations do |t|
      t.references :amigo, null: false, foreign_key: true
      t.string :address, limit: 250
      t.string :address_type, limit: 10
      t.string :floor, limit: 10
      t.string :building, limit: 10
      t.string :apartment_number, limit: 15
      t.string :street_number, limit: 15
      t.string :street_name, limit: 50
      t.string :street_suffix, limit: 15
      t.string :city, limit: 50
      t.string :county, limit: 50
      t.string :state_abbreviation, limit: 5
      t.string :country_code, limit: 5
      t.string :postal_code, limit: 10
      t.decimal :latitude, precision: 9, scale: 6
      t.decimal :longitude, precision: 9, scale: 6

      t.timestamps
    end
  end
end
