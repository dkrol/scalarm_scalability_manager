class CreateTimeWindows < ActiveRecord::Migration
  def change
    create_table :time_windows do |t|
      t.integer :length
      t.string :length_unit
    end
  end
end
