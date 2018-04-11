class CreateBrandings < ActiveRecord::Migration[5.1]
  def change
    create_table :brandings do |t|
      t.belongs_to :product, foreign_key: true
      t.belongs_to :brand, foreign_key: true
    end
  end
end
