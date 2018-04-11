class AddPrimaryKeyToPropertings < ActiveRecord::Migration[5.1]
  def change
    add_column :propertings, :id, :primary_key
  end
end
