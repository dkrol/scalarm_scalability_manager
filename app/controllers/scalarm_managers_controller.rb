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

end
