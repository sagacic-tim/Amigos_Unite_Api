class CreateEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :events do |t|
      t.string :event_name
      t.string :event_type
      t.string :event_speakers_performers, array: true, default: []
      t.date :event_date
      t.time :event_time
      # Add a reference to the event coordinator (an Amigo)
      t.bigint :event_coordinator_id, null: false

      t.timestamps
    end
    # Add a foreign key constraint to ensure data integrity
    add_foreign_key :events, :amigos, column: :event_coordinator_id
  end
end
