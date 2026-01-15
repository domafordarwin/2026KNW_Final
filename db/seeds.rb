# Development seed data for local testing.
ActiveRecord::Base.transaction do
  ReportAccess.delete_all
  Report.delete_all
  FeedbackAudit.delete_all
  TeacherFeedback.delete_all
  AiFeedbackCompiled.delete_all
  AiFeedbackRun.delete_all
  BookGuidance.delete_all
  BookCandidate.delete_all
  BookCatalog.delete_all
  TraitResult.delete_all
  MetricsResult.delete_all
  ScoringResult.delete_all
  Response.delete_all
  Submission.delete_all
  Session.delete_all
  AssessmentVersionItem.delete_all
  AssessmentVersion.delete_all
  Item.delete_all
  Passage.delete_all
  ParentLink.delete_all
  StudentProfile.delete_all
  SchoolClass.delete_all
  School.delete_all
  User.delete_all
  AnalyticsDomainAgg.delete_all
  AnalyticsSubskillAgg.delete_all
  AnalyticsTraitAgg.delete_all
end

admin = User.create!(role: "admin", status: "active", name: "Admin User", email_optional: "admin@example.com")
school_manager = User.create!(role: "school_manager", status: "active", name: "School Manager")
teacher = User.create!(role: "teacher", status: "active", name: "Teacher Kim", email_optional: "teacher@example.com")
student = User.create!(role: "student", status: "active", name: "Student Park")
parent = User.create!(role: "parent", status: "active", name: "Parent Park")

school = School.create!(name: "Hanbit Elementary")
school_class = SchoolClass.create!(school: school, grade: "3", name: "3-1")
StudentProfile.create!(
  student: student,
  school: school,
  school_class: school_class,
  student_code: "HB-301-0001",
  pii_ref_id: "pii-ref-0001"
)
ParentLink.create!(parent_user: parent, student: student, access_token: "parent-token-001", expires_at: 30.days.from_now)

passage = Passage.create!(
  title: "The Lost Kite",
  text: "Min found a kite tangled in a tree and tried to return it to its owner.",
  grade_band: "3-4",
  tags_json: { theme: "community", genre: "narrative" }
)

item1 = Item.create!(
  passage: passage,
  item_type: "multiple_choice",
  domain: "literal",
  subskill: "main_idea",
  difficulty: "easy",
  prompt: "What was Min trying to do?",
  choices_json: ["Fly a kite", "Return a kite", "Buy a kite", "Fix a kite"],
  answer_key_json: { correct_index: 1 },
  points: 1
)

item2 = Item.create!(
  passage: passage,
  item_type: "short_answer",
  domain: "inference",
  subskill: "reasoning",
  difficulty: "medium",
  prompt: "Why do you think Min helped?",
  rubric_json: { criteria: ["empathy", "responsibility"] },
  points: 2
)

version = AssessmentVersion.create!(name: "Grade3-FormA", status: "published", published_at: Time.current)
AssessmentVersionItem.create!(assessment_version: version, item: item1, order_no: 1)
AssessmentVersionItem.create!(assessment_version: version, item: item2, order_no: 2)

session = Session.create!(
  school: school,
  school_class: school_class,
  assessment_version: version,
  created_by_teacher: teacher,
  start_at: 2.days.ago,
  end_at: 1.day.from_now,
  status: "active",
  access_code: "ABCD1234"
)

submission = Submission.create!(
  session: session,
  student: student,
  started_at: 1.day.ago,
  submitted_at: Time.current,
  status: "submitted"
)

Response.create!(submission: submission, item: item1, answer_json: { selected_index: 1 }, time_spent: 35)
Response.create!(submission: submission, item: item2, answer_json: { text: "Because Min wanted to help the owner." }, time_spent: 75)

ScoringResult.create!(submission: submission, item: item1, score: 1, is_correct: true)
ScoringResult.create!(
  submission: submission,
  item: item2,
  score: 2,
  is_correct: true,
  rubric_breakdown_json: { empathy: 1, responsibility: 1 }
)

MetricsResult.create!(
  submission: submission,
  domain_scores_json: { literal: 90, inference: 85 },
  subskill_scores_json: { main_idea: 95, reasoning: 80 },
  percentile_json: { literal: 88, inference: 82 },
  computed_at: Time.current
)

TraitResult.create!(
  submission: submission,
  trait_type: "B",
  trait_scores_json: { curiosity: 0.7, persistence: 0.6 },
  computed_at: Time.current
)

AiFeedbackRun.create!(
  submission: submission,
  step: "item_analyzer",
  model: "gpt-4.1-mini",
  prompt_version: "v1",
  input_hash: "hash-001",
  output_json: { items: [{ item_id: item1.id, note: "Accurate main idea selection." }] },
  status: "success"
)

AiFeedbackCompiled.create!(
  submission: submission,
  compiled_json: {
    executive_summary: "Min demonstrates strong literal comprehension and good inference skills.",
    subskill_synthesis: {
      main_idea: "Consistently identifies key ideas.",
      reasoning: "Can explain motivations with evidence."
    },
    item_analysis: [
      { item_id: item1.id, feedback: "Clear understanding of the passage." },
      { item_id: item2.id, feedback: "Explains reasoning with empathy." }
    ],
    integrated: {
      domain_guidance: {
        literal: "Keep summarizing short passages.",
        inference: "Practice predicting character motives."
      },
      parent_summary: "Your child shows good understanding and empathy in reading."
    }
  }
)

TeacherFeedback.create!(
  submission: submission,
  editor_teacher: teacher,
  content_json: {
    executive_summary: "Strong comprehension with thoughtful inferences.",
    parent_summary: "Shows steady reading growth and empathy."
  },
  diff_json: { updated: ["executive_summary", "parent_summary"] },
  status: "approved",
  approved_at: Time.current
)

report = Report.create!(
  scope: "student",
  submission: submission,
  version: "v1",
  status: "final",
  template_version: "t1",
  storage_key: "reports/student/#{submission.id}.pdf"
)

ReportAccess.create!(
  report: report,
  subject_user: student,
  can_view: true,
  can_download: true
)
ReportAccess.create!(
  report: report,
  subject_user: parent,
  access_token: "share-token-001",
  can_view: true,
  can_download: true,
  expires_at: 30.days.from_now
)

book1 = BookCatalog.create!(
  isbn: "9780000000011",
  title: "The Kind Neighbor",
  author: "J. Lee",
  grade_band: "3-4",
  difficulty: "easy",
  tags_json: { theme: "kindness" },
  active: true
)
book2 = BookCatalog.create!(
  isbn: "9780000000012",
  title: "Mystery in the Park",
  author: "S. Choi",
  grade_band: "3-4",
  difficulty: "medium",
  tags_json: { theme: "mystery" },
  active: true
)

BookCandidate.create!(
  submission: submission,
  candidate_book_ids_json: [book1.id, book2.id],
  generated_at: Time.current
)
BookGuidance.create!(
  submission: submission,
  selected_book_ids_json: [book1.id],
  guidance_json: {
    activities: ["Summarize the main event", "Write a kind note to a character"],
    questions: ["Why did the neighbor help?", "What clues show kindness?"]
  }
)

AnalyticsDomainAgg.create!(
  session: session,
  school_class: school_class,
  domain: "literal",
  avg: 86.5,
  std: 8.2,
  dist_json: { "80-90" => 12, "90-100" => 5 }
)
AnalyticsSubskillAgg.create!(
  session: session,
  subskill: "main_idea",
  avg: 88.0,
  dist_json: { "80-90" => 10, "90-100" => 7 }
)
AnalyticsTraitAgg.create!(
  session: session,
  trait_type: "B",
  ratio: 0.45
)

puts "Seeded: admin=#{admin.id}, school_manager=#{school_manager.id}, teacher=#{teacher.id}, student=#{student.id}"
