require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user with all required attributes" do
    user = User.new(name: "Test User", role: "student", status: "active")
    assert user.valid?
  end

  test "invalid without name" do
    user = User.new(role: "student")
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "invalid without role" do
    user = User.new(name: "Test")
    assert_not user.valid?
  end

  test "role must be valid" do
    user = User.new(name: "Test", role: "invalid_role")
    assert_not user.valid?
    assert_includes user.errors[:role], "is not included in the list"
  end

  test "admin? returns true for admin role" do
    user = User.new(name: "Admin", role: "admin")
    assert user.admin?
    assert_not user.teacher?
    assert_not user.student?
  end

  test "teacher? returns true for teacher role" do
    user = User.new(name: "Teacher", role: "teacher")
    assert user.teacher?
    assert_not user.admin?
  end

  test "student? returns true for student role" do
    user = User.new(name: "Student", role: "student")
    assert user.student?
    assert_not user.teacher?
  end

  test "staff? returns true for admin, teacher, school_manager" do
    admin = User.new(name: "Admin", role: "admin")
    teacher = User.new(name: "Teacher", role: "teacher")
    manager = User.new(name: "Manager", role: "school_manager")
    student = User.new(name: "Student", role: "student")

    assert admin.staff?
    assert teacher.staff?
    assert manager.staff?
    assert_not student.staff?
  end

  test "email_optional must be unique when present" do
    User.create!(name: "User1", role: "student", email_optional: "test@example.com")
    user2 = User.new(name: "User2", role: "student", email_optional: "test@example.com")

    assert_not user2.valid?
    assert_includes user2.errors[:email_optional], "has already been taken"
  end

  test "password authentication works" do
    user = User.create!(
      name: "Test User",
      role: "student",
      email_optional: "auth@test.com",
      password: "securepassword"
    )

    assert user.authenticate("securepassword")
    assert_not user.authenticate("wrongpassword")
  end
end
