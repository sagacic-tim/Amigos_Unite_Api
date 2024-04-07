class CreateEventAmigoConnectors < ActiveRecord::Migration[7.0]
  def change
    create_table :event_amigo_connectors do |t|
      t.references :amigo, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.integer :role, default: 0, null: false

      t.timestamps
    end
end
