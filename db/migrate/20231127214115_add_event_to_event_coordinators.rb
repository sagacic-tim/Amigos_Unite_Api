class AddEventToEventCoordinators < ActiveRecord::Migration[7.0]
  def change
    add_reference :event_coordinators, :event, null: false, foreign_key: true
  end
end