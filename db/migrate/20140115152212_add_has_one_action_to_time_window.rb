class AddHasOneActionToTimeWindow < ActiveRecord::Migration

  def change
    add_reference :time_windows, :scaling_rule, index: true
  end

end
