class CreateProducts < ActiveRecord::Migration[5.1]
  def change
    create_table :products do |t|
      t.string :title
      t.boolean :is_available
      t.integer :remote_id
      t.belongs_to :category, foreign_key: true
      t.belongs_to :supplier, foreign_key: true
      t.string :url
      t.text :description
      t.string :collection
      t.string :color
      t.string :sizes
      t.integer :price
      t.string :images

      t.timestamps
    end
  end
end
