require 'test_helper'

class WorkerNodeTest < ActiveSupport::TestCase

  test "finding node without experiment_manager" do
    wn = WorkerNode.find_node_without('experiment')

    assert_not_nil wn
    assert_equal wn.url, '172.16.67.2'
  end

  test "finding node without db_instance" do
    wn = WorkerNode.find_node_without('storage')

    assert_not_nil wn
    assert_equal wn.url, '172.16.67.1'
  end


  test "finding node without db_config_service" do
    wn = WorkerNode.find_node_without('db_config_services')

    assert_nil wn
  end

end
