class AddFeedbackCount < ActiveRecord::Migration[5.1]
  def change
    add_column :products,    :feedback_count, :integer
    add_column :daily_facts, :feedback_count, :integer
  end
end
