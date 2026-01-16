require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "get login page" do
    get login_path
    assert_response :success
  end

  test "successful login redirects to dashboard" do
    user = User.create!(
      name: "Test Admin",
      email_optional: "login@test.com",
      role: "admin",
      status: "active",
      password: "password123"
    )

    post login_path, params: { email: "login@test.com", password: "password123" }
    assert_redirected_to admin_root_path
  end

  test "failed login shows error" do
    post login_path, params: { email: "wrong@test.com", password: "wrong" }
    assert_response :unprocessable_entity
  end

  test "logout clears session" do
    user = User.create!(
      name: "Test User",
      email_optional: "logout@test.com",
      role: "admin",
      status: "active",
      password: "password123"
    )

    post login_path, params: { email: "logout@test.com", password: "password123" }
    delete logout_path

    assert_redirected_to login_path
  end
end
