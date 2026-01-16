ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors, with: :threads)
    fixtures :all

    def sign_in_as(user)
      post login_path, params: { email: user.email_optional, password: "password123" }
    end

    def create_admin
      User.create!(
        name: "Admin User",
        email_optional: "admin@test.com",
        role: "admin",
        status: "active",
        password: "password123"
      )
    end

    def create_teacher
      User.create!(
        name: "Teacher User",
        email_optional: "teacher@test.com",
        role: "teacher",
        status: "active",
        password: "password123"
      )
    end

    def create_student
      User.create!(
        name: "Student User",
        email_optional: "student@test.com",
        role: "student",
        status: "active",
        password: "password123"
      )
    end

    def create_school
      School.create!(name: "Test School")
    end

    def create_class(school)
      SchoolClass.create!(school: school, grade: "3", name: "Class A")
    end
  end
end
