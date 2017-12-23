require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
 
 test "valid signup infomation" do 
   get signup_path
   assert_difference 'User.count', 1 do 
     post users_path, params: { user:{name: "user", 
                        email: "user@valid.com",
                        password: "1234",
                        password_confirmation: "1234" }}
   end
   follow_redirect!
   assert_template 'users/show'
 end
end
