require_relative 'storage_manager'

class DbInstanceManager < StorageManager

  def initialize(repo_url, service_folder)
    super(repo_url, service_folder)
  end

  def remote_installation_commands(worker_node, ssh_connection)
    # check if instance is already running
    instance_is_running = service_running?('instance', ssh_connection)
    Rails.logger.debug("Instance is running : #{instance_is_running}")
    return if instance_is_running


    #check if config is running
    download_manager(worker_node, ssh_connection) unless service_running?('config', ssh_connection)

    # start the instance
    cmd = [
      "source .rvm/environments/default",
      "ruby --version",
      "cd #{@service_folder}",
      "bundle install",
      "bundle exec rake db_instance:start"
    ].join(';')

    Rails.logger.debug(ssh_connection.exec!(cmd))
  end

  def manager_url(worker_node)
    "#{worker_node.url}:#{@db_instance_port}"
  end

  def stop_service
    # start the instance
    cmd = [
      "source .rvm/environments/default",
      "ruby --version",
      "cd #{@service_folder}",
      "bundle exec rake db_instance:stop"
    ].join(';')
  end

end