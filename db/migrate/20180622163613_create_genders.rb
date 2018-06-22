class CreateGenders < ActiveRecord::Migration[5.2]
  def change
    create_table :genders do |t|
      t.string :name, null: false

      t.timestamps null: false
    end

    create_join_table :genders, :nodes do |t|
      t.index [:gender_id, :node_id]
      t.index [:node_id, :gender_id]
    end
  end
end
