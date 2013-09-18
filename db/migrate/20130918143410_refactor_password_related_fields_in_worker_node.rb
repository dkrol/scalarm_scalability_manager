class RefactorPasswordRelatedFieldsInWorkerNode < ActiveRecord::Migration
  def change
    remove_column :worker_nodes, :password
    remove_column :worker_nodes, :password_salt
    add_column :worker_nodes, :password_hashed, :text
  end
end
