require 'scalarm_services/service_factory'

class ScalarmManagersController < ApplicationController

  def destroy
    manager = ScalarmManager.find(params[:id])

    begin
      manager.stop
      manager.destroy

      render json: { status: 'ok' }
    rescue Exception => e
      Rails.logger.error("Exception occured: #{e}")
      render json: { status: 'error' }
    end
  end

  def worker_nodes
    worker_nodes = WorkerNode.all.map do |wn|
      wn.user = '<NA>' if wn.user.nil?
      { url: wn.url, user: wn.user }
    end

    render json: worker_nodes
  end

  def managers
    managers = {}

    @information_service.scalarm_services.each do |service_name, service_label|
      managers[service_name] = ScalarmManager.where(service_type: service_name).to_a
    end
    #Rails.logger.debug("Managers: #{managers}")

    render json: managers
  end

  def manager_labels
    render json: @information_service.scalarm_services.to_json
  end

end
