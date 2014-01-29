require 'test_helper'

class TimeWindowTest < ActiveSupport::TestCase

  test "length in seconds calculations - seconds" do
    tw = TimeWindow.find(1)

    assert tw.get_length == 35
  end

  test "length in seconds calculations - minutes" do
    tw = TimeWindow.find(2)

    assert tw.get_length == 4800
  end

  test "length in seconds calculations - hours" do
    tw = TimeWindow.find(3)

    assert tw.get_length == 10800
  end

end
