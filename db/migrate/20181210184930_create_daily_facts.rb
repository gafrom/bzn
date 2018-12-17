class CreateDailyFacts < ActiveRecord::Migration[5.1]
  def change
    create_table :daily_facts do |t|
      t.integer :remote_id
      t.belongs_to :product, foreign_key: true
      t.belongs_to :category, foreign_key: true
      t.belongs_to :brand, foreign_key: true
      t.integer :original_price
      t.integer :discount_price
      t.integer :coupon_price
      t.integer :sold_count
      t.integer :rating
      t.boolean :is_available
      t.string :sizes, default: [], array: true

      t.date :created_at, null: false, index: true
    end

    add_index :daily_facts, [:product_id, :created_at]
  end
end
