require 'test_helper'

class Users::PressPassControllerTest < ActionDispatch::IntegrationTest
  test "should get login" do
    get users_press_pass_login_url
    assert_response :success
  end

  test "should get redirect" do
    get users_press_pass_redirect_url
    assert_response :success
  end

end
