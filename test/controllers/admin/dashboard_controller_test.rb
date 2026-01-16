require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      name: "Admin",
      email_optional: "admin@test.com",
      role: "admin",
      status: "active",
      password: "password123"
    )
  end

  test "admin can access dashboard" do
    post login_path, params: { email: "admin@test.com", password: "password123" }
    get admin_root_path
    assert_response :success
  end

  test "non-admin cannot access dashboard" do
    teacher = User.create!(
      name: "Teacher",
      email_optional: "teacher@test.com",
      role: "teacher",
      status: "active",
      password: "password123"
    )

    post login_path, params: { email: "teacher@test.com", password: "password123" }
    get admin_root_path
    assert_response :forbidden
  end

  test "unauthenticated user cannot access dashboard" do
    get admin_root_path
    assert_response :forbidden
  end
end
