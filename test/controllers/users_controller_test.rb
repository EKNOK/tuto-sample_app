require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:micheal)
    @other_user = users(:archer)
  end

  test "shouls redirect index when logged in" do
    get users_path
    assert_redirected_to login_url
  end

end
