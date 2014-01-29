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

  test "scaling experiment manager" do
    wn = WorkerNode.find(1)
    WorkerNode.expects(:find_node_without).with('experiment').returns(wn)
    ScalarmManager.expects(:remote_installation).with(wn, 'experiments').returns(nil)

    rule = ScalingRule.find(1)
    manager = ScalingAction.create_from_id(rule.action).execute

    assert_nil manager
  end

  test "scaling storage manager" do
    wn = WorkerNode.find(2)
    WorkerNode.expects(:find_node_without).with('storage').returns(wn)
    ScalarmManager.expects(:remote_installation).with(wn, 'db_instances').returns(ScalarmManager.new)

    rule = ScalingRule.find(4)
    assert_not_nil rule
    manager = ScalingAction.create_from_id(rule.action).execute

    assert_not_nil manager
  end


end
