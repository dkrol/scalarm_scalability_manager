class CreateCooldownPeriods < ActiveRecord::Migration
  def change
    create_table :cooldown_periods do |t|
      t.timestamp :start_at
      t.timestamp :end_at
    end
  end
end
