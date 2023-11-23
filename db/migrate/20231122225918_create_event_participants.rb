class CreateEventParticipants < ActiveRecord::Migration[7.0]
  def change
    create_table :event_participants do |t|
      t.references :amigo, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true

      t.timestamps
    end
  end
end
