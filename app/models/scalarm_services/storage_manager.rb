class StorageManager

  def initialize(repo_url, service_folder)
    @service_repo = repo_url
    @service_folder = service_folder
    @mongodb_version = "mongodb-linux-x86_64-2.4.8"
    @mongodb_url = "http://fastdl.mongodb.org/linux/#{@mongodb_version}.tgz"

    @db_instance_port = 30000
    @db_config_port = 28000
    @db_router_port = 27017
    @log_bank_port = 20001
    @log_bank_socket = '/tmp/scalarm_storage_manager.sock'
  end


  def adjust_load_balancer_config(worker_node)
    # empty on purpose
  end

  protected

  def service_running?(service, ssh_connection)
    proc_name = if service == 'router'
                  "./mongos .* --port 27017"
                elsif service == 'config'
                  "./mongod --configsvr .* --port 28000"
                elsif service == 'instance'
                  "./mongod .* --port 30000"
                end

    out = ssh_connection.exec!("ps aux | grep \"#{proc_name}\"")
    Rails.logger.debug(out)
    not (out.split("\n").delete_if{ |line| line.include? 'grep' }.empty?)
  end

  def scalarm_config_file
    scalarm_config = Rails.configuration.scalarm

    <<-END
# at which port the service should listen
information_service_url: #{scalarm_config['information_service']['url']}
information_service_user: #{scalarm_config['information_service']['user']}
information_service_pass: #{scalarm_config['information_service']['pass']}

# where log bank should store content
mongo_host: 'localhost'
mongo_port: 27017
db_name: 'scalarm_db'
binaries_collection_name: 'simulation_files'

# MongoDB settings
# host is optional - the service will take local ip address if host is not provided
#host: localhost

# MongoDB instance settings
db_instance_port: #{@db_instance_port}
db_instance_dbpath: ./../../scalarm_db_data
db_instance_logpath: ./../../log/scalarm_db.log

# MongoDB configsrv settings
db_config_port: #{@db_config_port}
db_config_dbpath: ./../../scalarm_db_config_data
db_config_logpath: ./../../log/scalarm_db_config.log

# MongoDB router settings
db_router_host: localhost
db_router_port: #{@db_router_port}
db_router_logpath: ./../../log/scalarm_db_router.log
    END
  end

  def web_server_config_file(worker_node)
    scalarm_config = Rails.configuration.scalarm
    load_balancer_url = scalarm_config['storage_manager_lb']['url']

    config = <<-END
pid: tmp/pids/thin.pid
log: log/thin.log
environment: production

    END

    Rails.logger.debug("Worker node url: #{worker_node.url} --- #{load_balancer_url}")

    config + if worker_node.url != load_balancer_url
               "port: #{@log_bank_port}"
             else
               "socket: #{@log_bank_socket}"
            end
  end

  def download_manager(worker_node, ssh_connection)
    # if not download code from github and mongodb
    cmd = [
        "rm -rf #{@service_folder}",
        "git clone #{@service_repo}",
        "cd #{@service_folder}",
        "wget #{@mongodb_url}",
        "tar xzvf #{@mongodb_version}.tgz",
        "mv #{@mongodb_version} mongodb",
        "echo \"#{scalarm_config_file}\" > config/scalarm.yml",
        "echo \"#{web_server_config_file(worker_node)}\" > config/thin.yml",
    ].join(';')

    Rails.logger.debug(ssh_connection.exec!(cmd))
  end


end