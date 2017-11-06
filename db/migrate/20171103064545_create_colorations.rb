class CreateColorations < ActiveRecord::Migration[5.1]
  def change
    create_table :colorations do |t|
      t.belongs_to :product, foreign_key: true
      t.belongs_to :color, foreign_key: true

      t.timestamps
    end
  end
end
