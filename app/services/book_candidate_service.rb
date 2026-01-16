class BookCandidateService
  def initialize(submission)
    @submission = submission
  end

  def generate_candidates
    trait = @submission.trait_result
    metrics = @submission.metrics_result
    student = @submission.student
    profile = student&.student_profile

    # Filter books from allowlist based on criteria
    candidates = BookCatalog.where(active: true)

    # Filter by grade band if available
    if profile&.school_class&.grade
      grade = profile.school_class.grade.to_i
      grade_band = determine_grade_band(grade)
      candidates = candidates.where(grade_band: grade_band) if grade_band
    end

    # Filter by difficulty based on trait
    if trait
      difficulty_levels = difficulty_for_trait(trait.trait_type)
      candidates = candidates.where(difficulty: difficulty_levels) if difficulty_levels.any?
    end

    candidate_ids = candidates.limit(10).pluck(:id)

    BookCandidate.find_or_initialize_by(submission: @submission).update!(
      candidate_book_ids_json: candidate_ids,
      generated_at: Time.current
    )

    candidate_ids
  end

  private

  def determine_grade_band(grade)
    case grade
    when 0..2 then "K-2"
    when 3..5 then "3-5"
    when 6..8 then "6-8"
    when 9..12 then "9-12"
    else nil
    end
  end

  def difficulty_for_trait(trait_type)
    case trait_type
    when "A" then ["medium", "hard"]
    when "B" then ["medium"]
    when "C" then ["easy", "medium"]
    when "D" then ["easy"]
    else []
    end
  end
end
