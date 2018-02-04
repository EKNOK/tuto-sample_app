require 'test_helper'

class RelationshipsControllerTest < ActionDispatch::IntegrationTest

  test "create should require logged-in user" do
    assert_no_difference 'Relationship.count' do
      post relatipnships_path
    end
  end

  test "destroy should require logged-in user" do
    assert_no_difference 'Relatipnship.count' do
      delete relationship_path(relationship(:one))
    end
    assert_redirected_to login_url
  end

end
