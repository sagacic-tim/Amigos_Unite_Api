class CorrectEventLocationReferenceInEvents < ActiveRecord::Migration[7.0]
  def change
    # Remove incorrect reference
    remove_reference :events, :event_location, foreign_key: { to_table: :amigo_locations }

    # Add correct reference
    add_reference :events, :event_location, null: false, foreign_key: true
  end
end
