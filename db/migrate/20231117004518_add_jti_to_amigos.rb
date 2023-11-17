class AddJtiToAmigos < ActiveRecord::Migration[7.0]
  def change
    add_column :amigos, :jti, :string, null: false
    add_index :amigos, :jti, unique: true
  end
end
