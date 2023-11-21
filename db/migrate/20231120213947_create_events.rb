class CreateEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :events do |t|
      t.string :event_name
      t.string :event_type
      t.string :event_speakers_performers, array: true, default: []
      t.date :event_date
      t.time :event_time
      t.references :event_coordinator, null: false, foreign_key: { to_table: :amigos }
      t.references :event_location, null: false, foreign_key: { to_table: :amigo_locations }

      t.timestamps
    end
  end
end
