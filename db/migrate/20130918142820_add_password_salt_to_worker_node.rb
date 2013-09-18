class AddPasswordSaltToWorkerNode < ActiveRecord::Migration
  def change
    add_column :worker_nodes, :password_salt, :text
  end
end
