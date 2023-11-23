class CreateEventCoordinators < ActiveRecord::Migration[7.0]
  def change
    create_table :event_coordinators do |t|
      t.references :event, null: false, foreign_key: true
      t.references :amigo, null: false, foreign_key: true
      t.boolean :is_active

      t.timestamps
    end
  end
end