class AddEventToEventLocations < ActiveRecord::Migration[7.0]
  def change
    add_reference :event_locations, :event, null: false, foreign_key: true                    
  end
end