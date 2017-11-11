class CreateLists < ActiveRecord::Migration[4.2]
  def self.up
    create_table :lists do |t|
      t.integer :user_id
      t.string :title
      t.timestamps
    end
  end

  def self.down
    drop_table :lists
  end
end
