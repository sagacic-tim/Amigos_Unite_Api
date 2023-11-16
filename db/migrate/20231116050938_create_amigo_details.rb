class CreateAmigoDetails < ActiveRecord::Migration[7.0]
  def change
    create_table :amigo_details do |t|
      t.date    :date_of_birth
      t.boolean :member_in_good_standing
      t.boolean :available_to_host
      t.boolean :willing_to_help
      t.boolean :willing_to_donate
      t.text    :personal_bio
      t.references :amigo, null: false, foreign_key: true

      t.timestamps
    end
  end
end
