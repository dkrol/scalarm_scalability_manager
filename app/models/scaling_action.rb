class ScalingAction
  attr_accessor :scalarm_service, :action_type

  def to_s
    label = ""
    case action_type
      when 'scale_up'
        label += 'Start a new instance of '
      when 'scale_down'
        label += 'Stop an instance of '
    end

    case scalarm_service
      when 'experiment'
        label += 'Experiment Manager'
      when 'storage'
        label += 'Storage Manager'
    end

    label
  end

  def get_id
    "#{scalarm_service}|||#{action_type}"
  end

  def self.create_from_id(full_id)
    sa = ScalingAction.new
    sa.scalarm_service = full_id.split('|||').first
    sa.action_type = full_id.split('|||').last

    sa
  end

  def self.get_actions
    actions = []

    %w(experiment storage).each do |scalarm_service|
      %w(scale_up scale_down).each do |action_type|
        action = ScalingAction.new
        action.scalarm_service = scalarm_service
        action.action_type = action_type
        actions << action
      end
    end

    actions
  end
end