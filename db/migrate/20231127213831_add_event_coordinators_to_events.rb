class AddEventCoordinatorsToEvents < ActiveRecord::Migration[7.0]
  def change
    add_reference :events, :event_coordinator, null: false, foreign_key: true
  end
end