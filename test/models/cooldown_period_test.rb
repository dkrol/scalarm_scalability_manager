require 'test_helper'

class CooldownPeriodTest < ActiveSupport::TestCase

  test "in cooldown period - correct" do
    assert CooldownPeriod.in_cooldown_period(Time.now) == true
  end

  test "in cooldown period - false check" do
    assert CooldownPeriod.in_cooldown_period(Time.now + 10.minutes) == false
  end

end
