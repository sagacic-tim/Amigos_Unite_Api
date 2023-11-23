class RenameIsCoordinatorToIsActiveInEventCoordinators < ActiveRecord::Migration[7.0]
  def change
    rename_column :event_coordinators, :is_coordinator, :is_active
  end
end
