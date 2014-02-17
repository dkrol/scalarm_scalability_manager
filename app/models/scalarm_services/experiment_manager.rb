class ExperimentManager
  attr_reader :service_port, :service_socket

  def initialize(repo_url, service_folder)
    @service_repo = repo_url
    @service_folder = service_folder
    @service_port = 3001
    @service_socket = '/tmp/scalarm_experiment_manager.sock'
  end

  def remote_installation_commands(worker_node, ssh_connection)
    Rails.logger.debug("Remove existing folder: #{remove_existing_folder_cmd}")
    Rails.logger.debug(ssh_connection.exec!(remove_existing_folder_cmd))

    Rails.logger.debug("Download code: #{download_code_cmd}")
    Rails.logger.debug(ssh_connection.exec!(download_code_cmd))

    Rails.logger.debug("Create configuration: #{create_configuration_cmd(worker_node)}")
    Rails.logger.debug(ssh_connection.exec!(create_configuration_cmd(worker_node)))

    Rails.logger.debug("install_dependencies_cmd: #{install_dependencies_cmd}")
    Rails.logger.debug(ssh_connection.exec!(install_dependencies_cmd))

    Rails.logger.debug("execution_prerequisite_cmd: #{execution_prerequisite_cmd}")
    Rails.logger.debug(ssh_connection.exec!(execution_prerequisite_cmd))

    Rails.logger.debug("start_service_cmd: #{start_service_cmd}")
    Rails.logger.debug(ssh_connection.exec!(start_service_cmd))
  end

  def remove_existing_folder_cmd
    [
        'source .rvm/environments/default',
        'ruby --version',
        "rm -rf #{@service_folder}"
    ].join(';')
  end

  def download_code_cmd
    [
        'source .rvm/environments/default',
        "git clone #{@service_repo}"
    ].join(';')
  end

  def create_configuration_cmd(worker_node)
    [
        'source .rvm/environments/default',
        "cd #{@service_folder}",
        "echo \"#{scalarm_config_file}\" > config/scalarm.yml",
        "echo \"#{puma_config_file(worker_node)}\" > config/puma.rb",
    ].join(';')
  end

  def install_dependencies_cmd
    [
        'source .rvm/environments/default',
        "cd #{@service_folder}",
        'bundle install'
    ].join(';')
  end

  def execution_prerequisite_cmd
    [
        'source .rvm/environments/default',
        "cd #{@service_folder}",
        'bundle exec rake db_router:start',
        'bundle exec rake service:non_digested',
    ].join(';')
  end

  def start_service_cmd
    [
        'source .rvm/environments/default',
        "cd #{@service_folder}",
        'bundle exec rake service:start',
    ].join(';')
  end

  def scalarm_config_file
    scalarm_config = Rails.configuration.scalarm

    <<-END
# at which port the service should listen
information_service_url: #{scalarm_config['information_service']['url']}
information_service_user: #{scalarm_config['information_service']['user']}
information_service_pass: #{scalarm_config['information_service']['pass']}
# mongo_activerecord config
db_name: 'scalarm_db'
# Monitoring section
monitoring:
  # table name within the server
  db_name: scalarm_monitoring
  interval: 30
  # which metric should be monitored
  # this is a list of names separeted with the ":" sign
  # currently the following list is supported
  metrics: cpu:memory
  #:memory:experiment_manager
    END
  end

  def puma_config_file(worker_node)
    scalarm_config = Rails.configuration.scalarm

    config = <<-END
environment 'production'
daemonize
stdout_redirect 'log/puma.log', 'log/puma.log.err', true
pidfile 'puma.pid'
threads 1,16

    END

    Rails.logger.debug("Worker node url: #{worker_node.url} --- #{scalarm_config['experiment_manager_lb']['url']}")

    config + if worker_node.url != scalarm_config['experiment_manager_lb']['url']
               "bind 'tcp://0.0.0.0:#{@service_port}'"
             else
               "bind 'unix://#{@service_socket}'"
            end
  end

  def stop_service
    [
        'source .rvm/environments/default',
        'ruby --version',
        "cd #{@service_folder}",
        'bundle exec rake db_router:stop',
        'bundle exec rake service:stop'
    ].join(';')
  end

  def adjust_load_balancer_config(worker_node)
    em_lb_config = Rails.configuration.scalarm['experiment_manager_lb']

    Net::SSH.start(em_lb_config['url'], em_lb_config['user']) do |ssh|
      lb_config = ssh.exec!("cat #{em_lb_config['config_file']}")

      lb_config = update_load_balancer_config(worker_node, em_lb_config['url'], lb_config)

      ssh.exec!("echo '#{lb_config}' > #{em_lb_config['config_file']}")
      ssh.exec!('service nginx restart')
    end
  end

  def update_load_balancer_config(worker_node, load_balancer_host_address, load_balancer_config)
    if worker_node.url == load_balancer_host_address
      unless load_balancer_config.include?('/tmp/scalarm_experiment_manager.sock')
        em_address = <<-EOD
      upstream scalarm_experiment_manager {
            server unix:/tmp/scalarm_experiment_manager.sock;
        EOD
        load_balancer_config.gsub!('upstream scalarm_experiment_manager {', em_address)
      end

    else
      unless load_balancer_config.include?("#{worker_node.url}:3001")
        em_address = <<-EOD
      upstream scalarm_experiment_manager {
            server #{worker_node.url}:3001;
        EOD
        load_balancer_config.gsub!('upstream scalarm_experiment_manager {', em_address)
      end
    end

    load_balancer_config
  end

  def manager_url(worker_node)
    em_lb_config = Rails.configuration.scalarm['experiment_manager_lb']

    if worker_node.url != em_lb_config['url']
      "#{worker_node.url}:#{@service_port}"
    else
      "#{worker_node.url}:#{@service_socket}"
    end
  end

end