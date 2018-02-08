require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def setup
    @user = User.new(name:"ExampleUser", email:"user@user.com",
              password: "1234", password_digest: "1234")
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "name should be present" do
    @user.name = " "
    assert_not @user.valid?
  end

  test "email should be present" do
    @user.email = " "
    assert_not @user.valid?
  end

  test "email validation should accept valid addresses" do
    valid_addresses = %w[user@user.com User01@user01.com USER02@user02.com]
    valid_addresses.each do |valid_address|
      @user.email = valid_address
      assert @user.valid?, "#{valid_address} should be valid"
    end
  end

  test "email validation should reject invalid addresses" do
    invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.
                           foo@bar_baz.com foo@bar+baz.com]
    invalid_addresses.each do |invalid_address|
      @user.email = invalid_address
      assert_not @user.valid?, "#{invalid_address.inspect} should be invalid"
    end
  end

  test "email addresses should be unique" do
    duplicate_user = @user.dup
    duplicate_user.email = @user.email.upcase
    @user.save
    assert_not duplicate_user.valid?
  end

  test "email address should be saved as lower-case" do
    mixed_case_email = "Foo@ExamplE.CoM"
    @user.email = mixed_case_email
    @user.save
    assert_equal mixed_case_email.downcase, @user.reload.email
  end

  test "authenticated? should return false for a user with nil digest" do
    assert_not @user.authenticated?(:remember, '')
  end

  test "associated microposts should be destroyed" do
    @user.save
    @user.microposts.create!(content: "hello")
    assert_difference `Micropost.count`, -1 do
      @user.destroy
    end
  end

  test "should follow and unfollow a user" do
    micheal = users(:micheal)
    archer = users(:archer)
    assert_not micheal.following?(archer)
    micheal.follow(archer)
    assert micheal.following?(archer)
    assert archer.followers.include?(micheal)
    micheal.unfollow(archer)
    assert_not micheal.following?(archer)
  end


  test "feed should have the right posts" do
    micheal = users(:micheal)
    archer  = users(:archer)
    lana    = users(:lana)
    # フォローしているユーザーの投稿を確認
    lana.microposts.each do |post_following|
      assert micheal.feed.include?(post_following)
    end
    # 自分自身の投稿を確認
    micheal.microposts.each do |post_self|
      assert micheal.feed.include?(post_self)
    end
    # フォローしていないユーザーの投稿を確認
    archer.microposts.each do |post_unfollowed|
      assert_not micheal.feed.include?(post_unfollowed)
    end
  end

end
