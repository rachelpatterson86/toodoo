class UpdateItemsLists < ActiveRecord::Migration
  def change

    change_column :items, :task_done, :boolean

  end
end
