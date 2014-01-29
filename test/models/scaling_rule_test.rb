require 'mocha'
require 'test_helper'

class ScalingRuleTest < ActiveSupport::TestCase

  test "simple rule - getting measurements" do
    db = MonitoringDatabase.new

    #db.expects(:get_measurements).with(){|metric, after_date, before_date, find_one|
    #  after_date.must_be_nil and before_date.must_be_nil and find_one == true
    #}.returns([{'date' => Time.now - 10.seconds, 'value' => 50}])
    db.expects(:get_measurements).returns([{'date' => Time.now - 10.seconds, 'value' => 50}])

    rule = ScalingRule.find(1)
    rule.db = db

    assert_not_nil rule

    measurements = rule.get_measurements

    assert_not_empty measurements
    assert measurements.size == 1
  end

  test "simple rule - fulfilled" do
    measurements = [{'date' => Time.now - 10.seconds, 'value' => 60}]

    rule = ScalingRule.find(1)
    assert rule.fulfilled?(measurements) == true
  end

  test "simple rule - not fulfilled" do
    measurements = [{'date' => Time.now - 10.seconds, 'value' => 40}]

    rule = ScalingRule.find(1)
    assert rule.fulfilled?(measurements) == false
  end

  test "window rule - fulfilled" do
    measurements = [{'value' => 60}, {'value' => 80}, {'value' => 90}]

    rule = ScalingRule.find(2)
    assert rule.fulfilled?(measurements) == true
  end

  test "window rule - not fulfilled" do
    measurements = [{'value' => 60}, {'value' => 80}, {'value' => 70}]

    rule = ScalingRule.find(3)
    assert rule.fulfilled?(measurements) == false
  end


end
