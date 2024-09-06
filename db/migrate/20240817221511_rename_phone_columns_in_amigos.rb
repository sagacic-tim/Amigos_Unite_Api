class RenamePhoneColumnsInAmigos < ActiveRecord::Migration[7.0]
  def change
    rename_column :amigos, :phone_1, :unformatted_phone_1
    rename_column :amigos, :phone_2, :unformatted_phone_2
  end
end
