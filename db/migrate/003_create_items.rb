class CreateItems < ActiveRecord::Migration
  def self.up
    create_table :items do |t|
      t.integer :list_id
      t.string :name
      t.date :due_date
      t.string :task_done
      t.timestamps
    end
  end

  def self.down
    drop_table :items
  end

end
