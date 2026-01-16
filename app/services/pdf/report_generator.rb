module Pdf
  class ReportGenerator
    include Prawn::View

    FONT_PATH = Rails.root.join("app", "assets", "fonts")

    def initialize(report)
      @report = report
      @submission = report.submission
      @student = @submission&.student
      @feedback = @submission&.teacher_feedback&.content_json ||
                  @submission&.ai_feedback_compiled&.compiled_json || {}
      @metrics = @submission&.metrics_result
    end

    def generate
      setup_document
      add_cover_page
      add_basic_info
      add_assessment_overview
      add_executive_summary
      add_domain_profile
      add_subskill_analysis
      add_item_analysis
      add_rubric_feedback
      add_trait_section
      add_domain_guidance
      add_book_guidance
      add_parent_summary
      add_appendix

      document.render
    end

    def filename
      student_name = @student&.name || "학생"
      date = Time.current.strftime("%Y%m%d")
      "문해력진단보고서_#{student_name}_#{date}.pdf"
    end

    private

    def setup_document
      # 한글 폰트 설정 (시스템 폰트 사용)
      font_families.update(
        "NotoSans" => {
          normal: font_path("NotoSansKR-Regular.ttf"),
          bold: font_path("NotoSansKR-Bold.ttf")
        }
      ) if font_exists?

      font "NotoSans" if font_exists?
    end

    def font_exists?
      File.exist?(font_path("NotoSansKR-Regular.ttf"))
    end

    def font_path(name)
      FONT_PATH.join(name).to_s
    end

    def document
      @document ||= Prawn::Document.new(
        page_size: "A4",
        margin: [40, 40, 40, 40],
        info: {
          Title: "문해력 진단 보고서",
          Author: "RNW 시스템",
          Subject: @student&.name,
          CreationDate: Time.current
        }
      )
    end

    def add_cover_page
      move_down 100
      text "문해력 진단 보고서", size: 28, style: :bold, align: :center
      move_down 30
      text "개인 리포트", size: 18, align: :center, color: "666666"
      move_down 50

      if @student
        text @student.name, size: 24, align: :center
        move_down 10
        if @student.student_profile
          profile = @student.student_profile
          text "#{profile.school&.name} #{profile.school_class&.name}", size: 14, align: :center, color: "666666"
        end
      end

      move_down 80
      text Time.current.strftime("%Y년 %m월 %d일"), size: 12, align: :center, color: "999999"

      start_new_page
    end

    def add_basic_info
      section_header "1. 기본 정보"

      data = [
        ["항목", "내용"],
        ["이름", @student&.name || "-"],
        ["검사일", @submission&.submitted_at&.strftime("%Y-%m-%d") || "-"],
        ["평가", @submission&.session&.assessment_version&.name || "-"]
      ]

      if @student&.student_profile
        profile = @student.student_profile
        data << ["학교", profile.school&.name || "-"]
        data << ["학급", profile.school_class&.name || "-"]
        data << ["학생 코드", profile.student_code || "-"]
      end

      table(data, width: bounds.width) do |t|
        t.row(0).font_style = :bold
        t.row(0).background_color = "EEEEEE"
        t.cells.padding = [8, 10]
        t.cells.border_width = 0.5
        t.column(0).width = 120
      end

      move_down 20
    end

    def add_assessment_overview
      section_header "2. 검사 개요"

      total_items = @submission&.responses&.count || 0
      total_score = @submission&.scoring_results&.sum(:score) || 0
      max_score = @submission&.session&.assessment_version&.items&.sum(:points) || 0

      text "본 검사는 학생의 문해력을 다양한 영역에서 진단합니다."
      move_down 10

      data = [
        ["총 문항 수", "#{total_items}문항"],
        ["총점", "#{total_score} / #{max_score}점"],
        ["소요 시간", "#{calculate_duration}분"]
      ]

      table(data, width: 300) do |t|
        t.cells.padding = [6, 10]
        t.cells.border_width = 0.5
        t.column(0).width = 120
        t.column(0).font_style = :bold
      end

      move_down 20
    end

    def add_executive_summary
      section_header "3. 종합 요약"

      summary = @feedback["executive_summary"] || "종합 요약 정보가 없습니다."
      text summary, leading: 4
      move_down 20
    end

    def add_domain_profile
      section_header "4. 영역별 프로파일"

      if @metrics&.domain_scores_json.present?
        domain_scores = @metrics.domain_scores_json

        data = [["영역", "점수", "수준"]]
        domain_scores.each do |domain, score|
          level = score_to_level(score.to_f)
          data << [domain_label(domain), "#{score}점", level]
        end

        table(data, width: bounds.width) do |t|
          t.row(0).font_style = :bold
          t.row(0).background_color = "EEEEEE"
          t.cells.padding = [8, 10]
          t.cells.border_width = 0.5
        end
      else
        text "영역별 점수 데이터가 없습니다.", color: "999999"
      end

      move_down 20
    end

    def add_subskill_analysis
      section_header "5. 하위 영역별 강점/약점"

      synthesis = @feedback["subskill_synthesis"]
      if synthesis.is_a?(Hash) && synthesis.any?
        synthesis.each do |skill, description|
          text "#{skill}:", style: :bold
          text description.to_s, leading: 3
          move_down 8
        end
      else
        text "하위 영역 분석 정보가 없습니다.", color: "999999"
      end

      move_down 20
    end

    def add_item_analysis
      section_header "6. 문항별 분석"

      analysis = @feedback["item_analysis"]
      if analysis.is_a?(Array) && analysis.any?
        analysis.each_with_index do |item, idx|
          text "문항 #{idx + 1}:", style: :bold
          if item.is_a?(Hash)
            text item["feedback"] || item.to_json, leading: 3
          else
            text item.to_s, leading: 3
          end
          move_down 6
        end
      else
        text "문항별 분석 정보가 없습니다.", color: "999999"
      end

      move_down 20
    end

    def add_rubric_feedback
      section_header "7. 서술형 문항 피드백"

      rubric_results = @submission&.scoring_results&.where("rubric_breakdown_json IS NOT NULL")
      if rubric_results&.any?
        rubric_results.each do |result|
          text "문항 #{result.item_id}:", style: :bold
          breakdown = result.rubric_breakdown_json || {}
          breakdown.each do |criterion, score|
            text "  • #{criterion}: #{score}점"
          end
          move_down 6
        end
      else
        text "서술형 문항 피드백 정보가 없습니다.", color: "999999"
      end

      move_down 20
    end

    def add_trait_section
      section_header "8. 독자 성향"

      trait_explanation = @feedback["trait_explanation"]
      if trait_explanation.present?
        text trait_explanation, leading: 4
      else
        trait_result = @submission&.trait_result
        if trait_result
          text "독자 유형: #{trait_result.trait_type}", style: :bold
          move_down 5
          text (trait_result.trait_scores_json || {}).to_json
        else
          text "독자 성향 정보가 없습니다.", color: "999999"
        end
      end

      move_down 20
    end

    def add_domain_guidance
      section_header "9. 영역별 학습 지도 방향"

      guidance = @feedback.dig("integrated", "domain_guidance") || @feedback["domain_guidance"]
      if guidance.is_a?(Hash) && guidance.any?
        guidance.each do |domain, advice|
          text "#{domain_label(domain)}:", style: :bold
          text advice.to_s, leading: 3
          move_down 8
        end
      else
        text "학습 지도 방향 정보가 없습니다.", color: "999999"
      end

      move_down 20
    end

    def add_book_guidance
      section_header "10. 추천 도서 및 독서 활동"

      book_guidance = @feedback.dig("integrated", "book_guidance") || @feedback["book_guidance"]
      if book_guidance.is_a?(Hash) && book_guidance.any?
        if book_guidance["books"].is_a?(Array)
          text "추천 도서:", style: :bold
          book_guidance["books"].each do |book|
            if book.is_a?(Hash)
              text "  • #{book['title']} - #{book['author']}"
            else
              text "  • #{book}"
            end
          end
          move_down 10
        end

        if book_guidance["activities"].present?
          text "독서 활동:", style: :bold
          text book_guidance["activities"].to_s, leading: 3
        end
      else
        # 책 후보에서 가져오기
        book_ids = @submission&.book_guidance&.selected_book_ids_json || []
        if book_ids.any?
          books = BookCatalog.where(id: book_ids)
          text "추천 도서:", style: :bold
          books.each do |book|
            text "  • #{book.title} - #{book.author}"
          end
        else
          text "추천 도서 정보가 없습니다.", color: "999999"
        end
      end

      move_down 20
    end

    def add_parent_summary
      section_header "11. 학부모님께 드리는 말씀"

      parent_summary = @feedback.dig("integrated", "parent_summary") || @feedback["parent_summary"]
      if parent_summary.present?
        text parent_summary, leading: 4
      else
        text "학부모 요약 정보가 없습니다.", color: "999999"
      end

      move_down 20
    end

    def add_appendix
      start_new_page
      section_header "12. 부록"

      text "검사 정보", style: :bold
      move_down 5

      data = [
        ["검사 버전", @submission&.session&.assessment_version&.name || "-"],
        ["검사 일시", @submission&.submitted_at&.strftime("%Y-%m-%d %H:%M") || "-"],
        ["보고서 생성일", Time.current.strftime("%Y-%m-%d %H:%M")],
        ["보고서 버전", @report.version || "1.0"]
      ]

      table(data, width: 300) do |t|
        t.cells.padding = [6, 10]
        t.cells.border_width = 0.5
        t.column(0).width = 120
      end

      move_down 30
      text "※ 본 보고서는 학생의 문해력 진단을 위한 참고 자료입니다.", size: 9, color: "666666"
      text "※ 보다 정확한 진단과 지도를 위해 담당 교사와 상담하시기 바랍니다.", size: 9, color: "666666"
    end

    def section_header(title)
      text title, size: 16, style: :bold
      stroke_horizontal_rule
      move_down 15
    end

    def calculate_duration
      return "-" unless @submission&.started_at && @submission&.submitted_at
      minutes = ((@submission.submitted_at - @submission.started_at) / 60).round
      minutes
    end

    def score_to_level(score)
      case score
      when 90..100 then "매우 우수"
      when 80..89 then "우수"
      when 70..79 then "보통"
      when 60..69 then "노력 필요"
      else "집중 지도 필요"
      end
    end

    def domain_label(key)
      labels = {
        "decoding" => "해독",
        "vocabulary" => "어휘",
        "fluency" => "유창성",
        "comprehension" => "독해",
        "inference" => "추론"
      }
      labels[key.to_s] || key.to_s
    end
  end
end
