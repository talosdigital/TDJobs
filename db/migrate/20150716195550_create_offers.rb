class CreateOffers < ActiveRecord::Migration
  def change
    create_table :offers do |t|
      t.references :job, index: true, foreign_key: true
      t.string :description
      t.integer :provider_id
      t.string :status

      t.timestamps null: false
    end
  end
end
