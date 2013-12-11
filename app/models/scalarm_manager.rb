require 'scalarm_services/service_factory'

class ScalarmManager < ActiveRecord::Base
  belongs_to :worker_node

  def self.remote_installation(worker_node, manager_type)
    em_lb_config = Rails.configuration.scalarm['experiment_manager_lb']

    scalarm_service = ScalarmServiceFactory.create_service(manager_type)

    begin
      Rails.logger.debug("Deployment of '#{manager_type}' on '#{worker_node.url}' - step I")
      Net::SSH.start(worker_node.url, worker_node.user, password: worker_node.password) do |ssh|
        # deployment procedure
        # 1. upload and start the code of the selected manager type at the specified worker node
        Rails.logger.debug(ssh.exec!(scalarm_service.remote_installation_commands(worker_node)))
      end

      # 2. update and restart load balancer of the selected manager type
      Rails.logger.debug("Deployment of '#{manager_type}' on '#{worker_node.url}' - step II")

      Net::SSH.start(em_lb_config['url'], em_lb_config['user']) do |ssh|
        if worker_node.url == em_lb_config['url']
          Rails.logger.debug("Bad option")

          unless lb_config.include?('/tmp/scalarm_experiment_manager.sock')
            em_address = <<-EOD
upstream scalarm_experiment_manager {
      server unix:/tmp/scalarm_experiment_manager.sock;
            EOD
            lb_config.gsub!('upstream scalarm_experiment_manager {', em_address)
          end
        else

          Rails.logger.debug("Good option")
          Rails.logger.debug("Do we have worker node already : #{lb_config.include?("#{worker_node.url}:3001")}")
          Rails.logger.debug("Do we have url already : #{lb_config.include?('upstream scalarm_experiment_manager {')}")

          unless lb_config.include?("#{worker_node.url}:3001")
            em_address = <<-EOD
upstream scalarm_experiment_manager {
      server #{worker_node.url}:3001;
            EOD
            lb_config.gsub!('upstream scalarm_experiment_manager {', em_address)
          end
        end

        Rails.logger.debug(lb_config)
        ssh.exec!("echo '#{lb_config}' > #{em_lb_config['config_file']}")
        ssh.exec!('service nginx restart')
      end

      # 3. create new manager instance locally unless error in previous step
      Rails.logger.debug("Deployment of '#{manager_type}' on '#{worker_node.url}' - step III")
      manager_url = if worker_node.url != em_lb_config['url']
                      "#{worker_node.url}:3001"
                    else
                      "#{worker_node.url}:/tmp/scalarm_experiment_manager.sock"
                    end
      manager = ScalarmManager.new(url: manager_url, service_type: manager_type)
      manager.worker_node = worker_node
      manager.save

  #    # 4. return the local manager instance as json object
      manager
    rescue Exception => e
      Rails.logger.error("An Exception occured during manager deployment: #{e}")
      nil
    end

  end

  def stop
    Rails.logger.debug("Stopping Scalarm service #{service_type} at #{worker_node.url}")
    scalarm_service = ScalarmServiceFactory.create_service(service_type)

    Net::SSH.start(worker_node.url, worker_node.user, password: worker_node.password) do |ssh|
      Rails.logger.debug(ssh.exec!(scalarm_service.stop_service))
    end
  end

  def self.label_to_name(manager_label)
    manager_label_map = {
        'Experiment Manager' => 'scalarm_experiment_manager'
    }

    manager_label_map[manager_label]
  end

  def self.thin_config_file(worker_node, manager_type, em_lb_config)
    case manager_type
      when 'scalarm_experiment_manager'
        config = <<-END
pid: tmp/pids/thin.pid
log: log/thin.log
environment: production
#servers: 6

        END
        config + if worker_node.url != em_lb_config['url']
                    'socket: /tmp/scalarm_experiment_manager.sock'
                  else
                    'port: 3001'
                  end
    end
  end

end
