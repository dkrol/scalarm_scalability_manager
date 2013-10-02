module ExperimentManager

  def stop_scalarm_experiment_manager
    Net::SSH.start(self.worker_node.url, self.worker_node.user, password: self.worker_node.password) do |ssh|
      ssh.exec!(remote_stop_commands)
    end
  end

  def remote_stop_commands
    manager_type = ScalarmManager.label_to_name(self.service_type)

    [
      'source .rvm/environments/default',
      "cd #{manager_type}",
      'bundle exec rake service:stop'
    ].join(';')
  end

end