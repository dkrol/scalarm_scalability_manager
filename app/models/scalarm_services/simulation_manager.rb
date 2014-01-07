class SimulationManager

  def initialize(repo_url, service_folder)
    @service_repo = repo_url
    @service_folder = service_folder
  end

  def deploy_manager(worker_node, experiment_id, login, password)
    begin
      Rails.logger.debug("Deployment of 'simulation_manager' on '#{worker_node.url}' - step I")
      options = {}
      options[:password] = worker_node.password unless worker_node.password.nil?

      Net::SSH.start(worker_node.url, worker_node.user, options) do |ssh|
        # deployment procedure
        # 1. upload and start the code of the selected manager type at the specified worker node
        remote_installation_commands(worker_node, ssh, experiment_id, login, password)
      end

      # 2. update and restart load balancer of the selected manager type
      #Rails.logger.debug("Deployment of '#{manager_type}' on '#{worker_node.url}' - step II")
      #scalarm_service.adjust_load_balancer_config(worker_node)

      # 3. create new manager instance locally unless error in previous step
      Rails.logger.debug("Deployment of 'simulation_manager' on '#{worker_node.url}' - step III")
      manager = ScalarmManager.new(url: worker_node.url, service_type: 'simulation_manager')
      manager.worker_node = worker_node
      manager.save

  #    # 4. return the local manager instance as json object
      manager
    rescue Exception => e
      Rails.logger.error("An Exception occured during manager deployment: #{e.message}")
      nil
    end
  end

  def remote_installation_commands(worker_node, ssh_connection, experiment_id, login, password)
    cmd = [
      'source .rvm/environments/default',
      'ruby --version',
      "rm -rf #{@service_folder}",
      "git clone #{@service_repo} #{@service_folder}",
      "cd #{@service_folder}/public/scalarm_simulation_manager",
      "echo \"#{config_file(experiment_id, login, password)}\" > config.json",
      'nohup ruby simulation_manager.rb  >/tmp/scalarm_sm_log 2>&1 &'
    ].join(';')

    Rails.logger.debug(cmd)
    Rails.logger.debug(ssh_connection.exec!(cmd))
  end

  def config_file(experiment_id, login, password)
    info_service_url = YAML.load_file(File.join(Rails.root, 'config', 'scalarm.yml'))['information_service']['url']

    {
        information_service_url: info_service_url,
        experiment_id: experiment_id,
        experiment_manager_user: login,
        experiment_manager_pass: password,
    }.to_json.gsub('"', '\"')
  end

  def stop_service
    [
      'source .rvm/environments/default',
      'ruby --version',
      "ps aux | grep simulation_manager | awk '{print $2}' | xargs kill -9"
    ].join(';')
  end

end