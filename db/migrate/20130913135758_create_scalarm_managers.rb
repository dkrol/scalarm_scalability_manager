class CreateScalarmManagers < ActiveRecord::Migration
  def change
    create_table :scalarm_managers do |t|
      t.string :url
      t.string :service_type
      t.references :worker_node

      t.timestamps
    end
  end
end
