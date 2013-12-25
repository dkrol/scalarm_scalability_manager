require_relative 'storage_manager'

class DbRouterManager < StorageManager

  def initialize(repo_url, service_folder)
    super(repo_url, service_folder)
  end

  def remote_installation_commands(worker_node, ssh_conn)
    # check if instance is already running
    instance_is_running = service_running?('router', ssh_conn)
    Rails.logger.debug("Router is running : #{instance_is_running}")
    return if instance_is_running


    #check if config is running
    unless service_running?('config', ssh_conn) or service_running?('instance', ssh_conn)
      download_manager(worker_node, ssh_conn)
    end

    # start the instance
    cmd = [
      "source .rvm/environments/default",
      "ruby --version",
      "cd #{@service_folder}",
      "bundle install",
      "bundle exec rake db_router:start"
    ].join(';')

    Rails.logger.debug(ssh_conn.exec!(cmd))
  end

  def manager_url(worker_node)
    "#{worker_node.url}:#{@db_router_port}"
  end

  def stop_service
    # start the instance
    [
      "source .rvm/environments/default",
      "ruby --version",
      "cd #{@service_folder}",
      "bundle exec rake db_router:stop"
    ].join(';')
  end

end