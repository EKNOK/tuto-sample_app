require 'test_helper'

class MicropostTest < ActiveSupport::TestCase

  def setup
    @user = users(:micheal)
    @micropost = Micropost.new(content: "Lorem ipsum", user_id: @user.id)
  end

  test "should be vaild" do
    assert @micropost.valid?
  end

  test "user id should be present" do
    @micropost.user_id = nil
    assert_not @micropost.valid?
  end


end
