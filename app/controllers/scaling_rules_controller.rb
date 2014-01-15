class ScalingRulesController < ApplicationController
  def index
    @monitoring_db = MonitoringDatabase.new

    @scaling_rules = ScalingRule.all
    @scaling_rule = ScalingRule.new

    @metrics = @monitoring_db.get_metrics
  end

  def create
    scaling_rule = ScalingRule.new(scaling_rule_params)
    scaling_rule.time_window = if scaling_rule.measurement_type == 'time_window'
                                 tw = TimeWindow.new
                                 tw.length = params[:time_window_length].to_i
                                 tw.length_unit = params[:time_window_length_unit]

                                 tw
                               else
                                 nil
                               end

    scaling_rule.save

    redirect_to scaling_rules_path
  end

  def destroy
  end

  private

  def scaling_rule_params
    params.require(:scaling_rule).permit(:metric, :measurement_type, :condition, :threshold, :action)
  end
end
