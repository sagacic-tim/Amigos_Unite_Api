class CreateEventLocationConnectors < ActiveRecord::Migration[7.1]
  def change
    create_table :event_location_connectors do |t|
      t.references :event, null: false, foreign_key: true
      t.references :event_location, null: false, foreign_key: true

      t.timestamps
    end
  end
end