class ScalingRulesController < ApplicationController
  def index
    @scaling_rules = ScalingRule.all
    @scaling_rule = ScalingRule.new
  end

  def create
  end

  def destroy
  end
end
