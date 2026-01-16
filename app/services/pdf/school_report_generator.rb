module Pdf
  class SchoolReportGenerator
    include Prawn::View

    def initialize(report)
      @report = report
      @session = report.session
      @school = @session&.school
    end

    def generate
      setup_document
      add_cover_page
      add_overview
      add_participation_stats
      add_domain_distribution
      add_subskill_weakness
      add_trait_distribution
      add_insights
      add_program_proposal

      document.render
    end

    def filename
      school_name = @school&.name || "학교"
      date = Time.current.strftime("%Y%m%d")
      "학교문해력보고서_#{school_name}_#{date}.pdf"
    end

    private

    def setup_document
      # 폰트 설정은 학생 보고서와 동일
    end

    def document
      @document ||= Prawn::Document.new(
        page_size: "A4",
        margin: [40, 40, 40, 40],
        info: {
          Title: "학교 문해력 진단 보고서",
          Author: "RNW 시스템",
          Subject: @school&.name,
          CreationDate: Time.current
        }
      )
    end

    def add_cover_page
      move_down 100
      text "학교 문해력 진단 보고서", size: 28, style: :bold, align: :center
      move_down 30
      text "학교 통계 리포트", size: 18, align: :center, color: "666666"
      move_down 50

      if @school
        text @school.name, size: 24, align: :center
      end

      if @session
        move_down 20
        text "평가: #{@session.assessment_version&.name}", size: 14, align: :center, color: "666666"
      end

      move_down 80
      text Time.current.strftime("%Y년 %m월 %d일"), size: 12, align: :center, color: "999999"

      start_new_page
    end

    def add_overview
      section_header "1. 개요"

      submissions = @session&.submissions || []
      total_students = submissions.count
      completed = submissions.where(status: "submitted").count

      data = [
        ["항목", "내용"],
        ["학교명", @school&.name || "-"],
        ["평가명", @session&.assessment_version&.name || "-"],
        ["전체 학생 수", "#{total_students}명"],
        ["제출 완료", "#{completed}명"],
        ["참여율", total_students > 0 ? "#{(completed.to_f / total_students * 100).round(1)}%" : "-"]
      ]

      table(data, width: bounds.width) do |t|
        t.row(0).font_style = :bold
        t.row(0).background_color = "EEEEEE"
        t.cells.padding = [8, 10]
        t.cells.border_width = 0.5
        t.column(0).width = 150
      end

      move_down 20
    end

    def add_participation_stats
      section_header "2. 참여 현황"

      submissions = @session&.submissions || []

      status_counts = {
        "not_started" => submissions.where(status: "not_started").count,
        "in_progress" => submissions.where(status: "in_progress").count,
        "submitted" => submissions.where(status: "submitted").count
      }

      data = [
        ["상태", "학생 수", "비율"],
        ["미시작", status_counts["not_started"], percentage(status_counts["not_started"], submissions.count)],
        ["진행 중", status_counts["in_progress"], percentage(status_counts["in_progress"], submissions.count)],
        ["제출 완료", status_counts["submitted"], percentage(status_counts["submitted"], submissions.count)]
      ]

      table(data, width: 400) do |t|
        t.row(0).font_style = :bold
        t.row(0).background_color = "EEEEEE"
        t.cells.padding = [8, 10]
        t.cells.border_width = 0.5
      end

      move_down 20
    end

    def add_domain_distribution
      section_header "3. 영역별 점수 분포"

      domain_aggs = AnalyticsDomainAgg.where(session: @session)

      if domain_aggs.any?
        data = [["영역", "평균", "표준편차"]]
        domain_aggs.each do |agg|
          data << [domain_label(agg.domain), "#{agg.avg&.round(1)}점", "#{agg.std&.round(2)}"]
        end

        table(data, width: bounds.width) do |t|
          t.row(0).font_style = :bold
          t.row(0).background_color = "EEEEEE"
          t.cells.padding = [8, 10]
          t.cells.border_width = 0.5
        end
      else
        text "영역별 통계 데이터가 없습니다.", color: "999999"
      end

      move_down 20
    end

    def add_subskill_weakness
      section_header "4. 하위 영역별 취약점"

      subskill_aggs = AnalyticsSubskillAgg.where(session: @session).order(avg: :asc).limit(5)

      if subskill_aggs.any?
        text "평균 점수가 낮은 하위 영역 (상위 5개):", style: :bold
        move_down 10

        data = [["하위 영역", "평균 점수"]]
        subskill_aggs.each do |agg|
          data << [agg.subskill, "#{agg.avg&.round(1)}점"]
        end

        table(data, width: 300) do |t|
          t.row(0).font_style = :bold
          t.row(0).background_color = "EEEEEE"
          t.cells.padding = [8, 10]
          t.cells.border_width = 0.5
        end
      else
        text "하위 영역 통계 데이터가 없습니다.", color: "999999"
      end

      move_down 20
    end

    def add_trait_distribution
      section_header "5. 독자 성향 분포"

      trait_aggs = AnalyticsTraitAgg.where(session: @session)

      if trait_aggs.any?
        data = [["독자 유형", "비율"]]
        trait_aggs.each do |agg|
          data << [agg.trait_type, "#{(agg.ratio * 100).round(1)}%"]
        end

        table(data, width: 300) do |t|
          t.row(0).font_style = :bold
          t.row(0).background_color = "EEEEEE"
          t.cells.padding = [8, 10]
          t.cells.border_width = 0.5
        end
      else
        text "독자 성향 분포 데이터가 없습니다.", color: "999999"
      end

      move_down 20
    end

    def add_insights
      section_header "6. 주요 인사이트"

      text "본 학교의 문해력 진단 결과를 바탕으로 한 주요 인사이트입니다.", leading: 4
      move_down 10

      # 영역별 강약점 분석
      domain_aggs = AnalyticsDomainAgg.where(session: @session).order(avg: :desc)
      if domain_aggs.any?
        strongest = domain_aggs.first
        weakest = domain_aggs.last

        text "• 강점 영역: #{domain_label(strongest.domain)} (평균 #{strongest.avg&.round(1)}점)", leading: 4
        text "• 약점 영역: #{domain_label(weakest.domain)} (평균 #{weakest.avg&.round(1)}점)", leading: 4
      end

      move_down 20
    end

    def add_program_proposal
      start_new_page
      section_header "7. 프로그램 제안"

      text "학교 전체의 문해력 향상을 위한 프로그램 제안입니다.", leading: 4
      move_down 15

      # 약점 영역 기반 제안
      weak_subskills = AnalyticsSubskillAgg.where(session: @session).order(avg: :asc).limit(3)

      if weak_subskills.any?
        text "집중 개선 필요 영역:", style: :bold
        move_down 5
        weak_subskills.each do |agg|
          text "  • #{agg.subskill}: 집중 보충 프로그램 권장"
        end
        move_down 15
      end

      text "권장 활동:", style: :bold
      move_down 5
      text "  • 독서 동아리 활동 강화"
      text "  • 어휘력 향상 프로그램"
      text "  • 독해력 집중 훈련"
      text "  • 학부모 독서 지도 워크숍"

      move_down 30
      text "※ 본 보고서는 학교 단위 문해력 진단 결과를 요약한 것입니다.", size: 9, color: "666666"
      text "※ 세부 지도 방안은 담당 교사와 협의하시기 바랍니다.", size: 9, color: "666666"
    end

    def section_header(title)
      text title, size: 16, style: :bold
      stroke_horizontal_rule
      move_down 15
    end

    def percentage(count, total)
      return "0%" if total == 0
      "#{(count.to_f / total * 100).round(1)}%"
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
