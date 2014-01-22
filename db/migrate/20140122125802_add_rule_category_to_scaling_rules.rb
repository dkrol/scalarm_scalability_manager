class AddRuleCategoryToScalingRules < ActiveRecord::Migration
  def change
    add_column :scaling_rules, :rule_category, :string
  end
end
