class RenameRoomToRoomSuiteNoInEventLocations < ActiveRecord::Migration[7.0]
  def change
    rename_column :event_locations, :room, :room_suite_no
  end
end