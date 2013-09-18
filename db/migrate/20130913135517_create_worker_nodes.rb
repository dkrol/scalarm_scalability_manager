class CreateWorkerNodes < ActiveRecord::Migration
  def change
    create_table :worker_nodes do |t|
      t.string :url
      t.boolean :experiment_manager_compatible
      t.boolean :storage_manager_compatible
      t.boolean :simulation_manager_compatible
      t.boolean :ignored

      t.timestamps
    end
  end
end
