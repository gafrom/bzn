class CreateHourlyFacts < ActiveRecord::Migration[5.1]
  def change
    create_table :hourly_facts do |t|
      t.belongs_to :product, foreign_key: true
      t.string :sizes, default: [], array: true

      t.timestamps
    end

    add_index :hourly_facts, :created_at
  end
end
