class UpdateItemsLists < ActiveRecord::Migration[4.2]
  def change
    change_column :items, :task_done, :boolean
  end
end
