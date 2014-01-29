class CooldownPeriod < ActiveRecord::Base

  def self.in_cooldown_period(timestamp)
    last_cooldown = CooldownPeriod.order('end_at DESC').first

    (not last_cooldown.nil?) and last_cooldown.end_at >= timestamp and last_cooldown.start_at <= timestamp
  end

end
