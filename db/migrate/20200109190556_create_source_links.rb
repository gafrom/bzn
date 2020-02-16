class CreateSourceLinks < ActiveRecord::Migration[5.1]
  def change
    create_table :source_links do |t|
      t.belongs_to :sync_task, foreign_key: true
      t.string :status
      t.string :url

      t.timestamps
    end
  end
end
