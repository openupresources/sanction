class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table :people, :id => false do |t|
      # to test for non-standard primary_key compliance
      t.integer :unique_id
      t.string :name
    end
  end
  def self.down
    drop_table :people
  end
end
