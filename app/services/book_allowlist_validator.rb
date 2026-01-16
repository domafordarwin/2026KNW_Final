# 도서 Allowlist 검증 서비스
# LLM이 추천한 도서가 승인된 도서 목록(allowlist)에 있는지 검증합니다.
class BookAllowlistValidator
  ValidationResult = Struct.new(:valid, :approved_books, :rejected_books, :replacement_suggestions, keyword_init: true)

  def initialize
    @active_books = BookCatalog.where(active: true)
  end

  # LLM 추천 도서 목록을 검증하고 필터링
  # @param recommended_books [Array<Hash>] LLM이 추천한 도서 목록 (title, author 포함)
  # @param grade_band [String, nil] 학년군 필터 (예: "3-5")
  # @return [ValidationResult] 검증 결과
  def validate(recommended_books, grade_band: nil)
    return empty_result if recommended_books.blank?

    approved = []
    rejected = []
    replacements = {}

    recommended_books.each do |book|
      title = normalize_title(book["title"] || book[:title])
      author = normalize_author(book["author"] || book[:author])

      # ISBN으로 정확히 매칭되면 우선
      if book["isbn"].present? || book[:isbn].present?
        isbn = book["isbn"] || book[:isbn]
        match = find_by_isbn(isbn)
        if match
          approved << format_book(match)
          next
        end
      end

      # 제목으로 검색
      match = find_by_title_and_author(title, author, grade_band)

      if match
        approved << format_book(match)
      else
        rejected << { title: book["title"] || book[:title], author: book["author"] || book[:author], reason: "allowlist에 없음" }
        # 대체 도서 제안
        suggestions = find_similar_books(title, grade_band)
        replacements[title] = suggestions if suggestions.any?
      end
    end

    ValidationResult.new(
      valid: rejected.empty?,
      approved_books: approved,
      rejected_books: rejected,
      replacement_suggestions: replacements
    )
  end

  # 도서 ID 목록의 유효성 검증
  # @param book_ids [Array<Integer>] 검증할 도서 ID 목록
  # @return [Hash] { valid_ids: [], invalid_ids: [] }
  def validate_ids(book_ids)
    return { valid_ids: [], invalid_ids: [] } if book_ids.blank?

    valid_ids = @active_books.where(id: book_ids).pluck(:id)
    invalid_ids = book_ids - valid_ids

    { valid_ids: valid_ids, invalid_ids: invalid_ids }
  end

  # 특정 조건에 맞는 대체 도서 추천
  # @param count [Integer] 추천할 도서 수
  # @param grade_band [String, nil] 학년군 필터
  # @param difficulty [String, nil] 난이도 필터
  # @param tags [Array<String>] 태그 필터
  # @return [Array<Hash>] 추천 도서 목록
  def suggest_alternatives(count: 5, grade_band: nil, difficulty: nil, tags: [])
    scope = @active_books

    scope = scope.where(grade_band: grade_band) if grade_band.present?
    scope = scope.where(difficulty: difficulty) if difficulty.present?

    if tags.any?
      # tags_json 필드에서 태그 검색 (SQLite의 JSON 함수 활용)
      tags.each do |tag|
        scope = scope.where("tags_json LIKE ?", "%#{tag}%")
      end
    end

    scope.limit(count).map { |book| format_book(book) }
  end

  private

  def empty_result
    ValidationResult.new(
      valid: true,
      approved_books: [],
      rejected_books: [],
      replacement_suggestions: {}
    )
  end

  def normalize_title(title)
    return "" if title.blank?
    title.to_s.strip.downcase.gsub(/[^\p{L}\p{N}\s]/u, "")
  end

  def normalize_author(author)
    return "" if author.blank?
    author.to_s.strip.downcase.gsub(/[^\p{L}\p{N}\s]/u, "")
  end

  def find_by_isbn(isbn)
    return nil if isbn.blank?
    @active_books.find_by(isbn: isbn.to_s.gsub(/[-\s]/, ""))
  end

  def find_by_title_and_author(title, author, grade_band = nil)
    scope = @active_books

    # 정확한 제목 매치 시도
    exact_match = scope.find_by("LOWER(title) = ?", title)
    return exact_match if exact_match

    # 부분 매치 시도
    partial_matches = scope.where("LOWER(title) LIKE ?", "%#{title}%")

    # 학년군 필터링
    partial_matches = partial_matches.where(grade_band: grade_band) if grade_band.present?

    # 저자 매칭으로 정확도 높이기
    if author.present? && partial_matches.count > 1
      author_match = partial_matches.find_by("LOWER(author) LIKE ?", "%#{author}%")
      return author_match if author_match
    end

    partial_matches.first
  end

  def find_similar_books(title, grade_band = nil)
    return [] if title.blank?

    # 제목에서 키워드 추출
    keywords = title.split(/\s+/).select { |w| w.length > 2 }.first(3)
    return [] if keywords.empty?

    scope = @active_books
    scope = scope.where(grade_band: grade_band) if grade_band.present?

    # 키워드 기반 유사 도서 검색
    suggestions = []
    keywords.each do |keyword|
      matches = scope.where("LOWER(title) LIKE ?", "%#{keyword}%").limit(3)
      matches.each do |book|
        suggestions << format_book(book) unless suggestions.any? { |s| s[:id] == book.id }
      end
      break if suggestions.count >= 3
    end

    # 태그 기반 대체 도서 추가
    if suggestions.count < 3
      similar_by_tags = scope.limit(3 - suggestions.count)
      similar_by_tags.each do |book|
        suggestions << format_book(book) unless suggestions.any? { |s| s[:id] == book.id }
      end
    end

    suggestions.first(3)
  end

  def format_book(book)
    {
      id: book.id,
      title: book.title,
      author: book.author,
      isbn: book.isbn,
      grade_band: book.grade_band,
      difficulty: book.difficulty,
      tags: book.tags_json
    }
  end
end
