class DeviseCreateAmigos < ActiveRecord::Migration[7.0]
  def change
    create_table :amigos do |t|
      ## Database authenticatable
      t.string :first_name, limit: 50
      t.string :last_name, limit: 50
      t.string :user_name, null: false, default: "", limit: 50
      t.string :email, null: false, default: "", limit: 50
      t.string :secondary_email, default: "", limit: 50
      t.string :phone_1, limit: 20
      t.string :phone_2, limit: 20
      t.string :encrypted_password, null: false, default: ""

      ## Add JTI - Jason Web Token Index
      t.string :jti, null: false

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email

      ## Lockable
      t.integer  :failed_attempts, default: 0, null: false
      t.string   :unlock_token
      t.datetime :locked_at

      t.timestamps null: false
    end

    add_index :amigos, :user_name,            unique: true
    add_index :amigos, :email,                unique: true
    add_index :amigos, :reset_password_token, unique: true
    add_index :amigos, :confirmation_token,   unique: true
    add_index :amigos, :unlock_token,         unique: true
    add_index :amigos, :jti,                  unique: true
  end
end
