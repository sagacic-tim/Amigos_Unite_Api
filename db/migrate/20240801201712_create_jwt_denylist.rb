class CreateJwtDenylist < ActiveRecord::Migration[7.1]
  def change
    create_table :jwt_denylist do |t|
      t.string :jti, null: false
      t.timestamps
    end
    add_index :jwt_denylist, :jti, unique: true
  end

  def down
    remove_index :jwt_denylist, :jti if index_exists?(:jwt_denylist, :jti)
    drop_table :jwt_denylist if table_exists?(:jwt_denylist)
  end
end