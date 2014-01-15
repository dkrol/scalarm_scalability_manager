class CreateScalingRules < ActiveRecord::Migration
  def change
    create_table :scaling_rules do |t|
      t.string :metric
      t.string :measurement_type
      t.string :condition
      t.string :threshold
      t.string :action

      t.timestamps
    end
  end
end
