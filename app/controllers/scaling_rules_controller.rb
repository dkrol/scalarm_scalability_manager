class ScalingRulesController < ApplicationController
  def index
    @monitoring_db = MonitoringDatabase.new

    @scaling_rules = ScalingRule.all
    @scaling_rule = ScalingRule.new

    @metrics = @monitoring_db.get_metrics
  end

  def create
    scaling_rule = ScalingRule.new(scaling_rule_params)
    scaling_rule.rule_category = params[:rule_category]
    scaling_rule.measurement_type = params[:measurement_type]

    scaling_rule.time_window = if scaling_rule.measurement_type == 'time_window'
                                 tw = TimeWindow.new
                                 tw.length = params[:time_window_length].to_i
                                 tw.length_unit = params[:time_window_length_unit]

                                 tw
                               else
                                 nil
                               end
    scaling_rule.save

    scaling_rule.start_monitoring_process

    redirect_to scaling_rules_path
  end

  def destroy
    scaling_rule = ScalingRule.find(params[:id])
    scaling_rule.stop_monitoring_process
    scaling_rule.destroy

    flash[:notice] = 'Selected scaling rule has been destroyed'

    redirect_to scaling_rules_path
  end

  private

  def scaling_rule_params
    params.require(:scaling_rule).permit(:metric, :measurement_type, :condition, :threshold, :action)
  end
end
