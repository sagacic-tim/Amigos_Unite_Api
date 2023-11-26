class AddPhoneToEventLocations < ActiveRecord::Migration[7.0]
  def change
    add_column :event_locations, :phone, :string, limit: 20
  end
end
