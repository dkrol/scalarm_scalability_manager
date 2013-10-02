class ScalarmManagersController < ApplicationController

  def destroy
    manager = ScalarmManager.find(params[:id])

    begin
      manager.send("stop_#{ScalarmManager.label_to_name(manager.service_type)}")

      manager.destroy

      render json: { status: 'ok' }
    rescue Exception => e
      render json: { status: 'error' }
    end
  end

end
