class CreateRemoteData < ActiveRecord::Migration[5.1]
  def change
    create_table :remote_data do |t|
      t.integer :remote_id, index: true

      t.timestamps
    end
  end
end
