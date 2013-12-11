require 'net/ssh'

class PlatformController < ApplicationController
  before_filter :load_information_manager

  def index
    @worker_nodes = WorkerNode.all

    @managers = group_scalarm_services
  end

  def synchronize
    ScalarmManager.delete_all
    WorkerNode.delete_all

    @information_service.scalarm_services.each do |service_name, service_label|
      @information_service.get_list_of(service_name).each do |manager_url|
        node_address = manager_url.split(':').first
        node = WorkerNode.find_by_url(node_address)
        node = WorkerNode.new(url: node_address) if node.nil?

        manager = ScalarmManager.find_by_url(manager_url)
        manager = ScalarmManager.new({url: manager_url, service_type: service_name}) if manager.nil?

        node.scalarm_managers << manager unless node.scalarm_managers.include?(manager)
        manager.worker_node = node unless manager.worker_node == node

        node.save
        manager.save
      end
    end

    render json: { worker_nodes: WorkerNode.all, managers: group_scalarm_services }
  end

  def addWorkerNode
    worker_node = WorkerNode.new({url: params[:url], user: params[:user]})
    worker_node.password = params[:password]
    worker_node.save

    render json: worker_node
  end

  def removeWorkerNode
    WorkerNode.destroy_all({id: params[:worker_node_id]})

    render json: { status: 'ok' }
  end

  def deployManager
    manager_type = params[:managerType]
    worker_node = WorkerNode.find(params[:worker_node_id])

    manager = ScalarmManager.remote_installation(worker_node, manager_type)

    render json: manager
  end

  protected

  def load_information_manager
    @config = YAML.load_file(File.join(Rails.root, 'config', 'scalarm.yml'))
    @information_service = InformationService.new(@config)
  end

  def group_scalarm_services
    managers = {}
    
    @information_service.scalarm_services.each do |service_name, service_label|
      managers[service_name] = ScalarmManager.where(service_type: service_name).to_a
    end
    
    Rails.logger.debug("Managers: #{managers}")

    managers
  end
end
