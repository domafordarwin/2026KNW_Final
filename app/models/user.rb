class User < ApplicationRecord
  has_secure_password validations: false

  has_one :student_profile, foreign_key: :student_id, dependent: :destroy
  has_many :parent_links, foreign_key: :parent_user_id, dependent: :destroy
  has_many :student_parent_links, class_name: "ParentLink", foreign_key: :student_id, dependent: :destroy

  # Teacher relationships
  has_many :created_sessions, class_name: "Session", foreign_key: :created_by_teacher_id
  has_many :teacher_feedbacks, foreign_key: :editor_teacher_id
  has_many :feedback_audits, foreign_key: :actor_id

  # Student relationships
  has_many :submissions, foreign_key: :student_id

  validates :name, presence: true
  validates :role, presence: true, inclusion: { in: %w[admin school_manager teacher student parent] }
  validates :email_optional, uniqueness: true, allow_blank: true

  scope :admins, -> { where(role: "admin") }
  scope :school_managers, -> { where(role: "school_manager") }
  scope :teachers, -> { where(role: "teacher") }
  scope :students, -> { where(role: "student") }
  scope :parents, -> { where(role: "parent") }
  scope :active, -> { where(status: "active") }

  def admin?
    role == "admin"
  end

  def school_manager?
    role == "school_manager"
  end

  def teacher?
    role == "teacher"
  end

  def student?
    role == "student"
  end

  def parent?
    role == "parent"
  end

  def staff?
    admin? || school_manager? || teacher?
  end
end
