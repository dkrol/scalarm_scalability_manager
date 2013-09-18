class AddUserAndPasswordToWorkerNodes < ActiveRecord::Migration
  def change
    add_column :worker_nodes, :user, :text
    add_column :worker_nodes, :password, :text
  end
end
