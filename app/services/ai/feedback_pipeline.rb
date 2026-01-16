module Ai
  class FeedbackPipeline
    PROMPT_VERSION = "v1.1"

    def initialize(submission)
      @submission = submission
      @client = OpenaiClient.new
      @cache = ResponseCache.new
      @pii_redactor = PiiRedactor.new
      @student = submission.student
    end

    def run(section: nil)
      # 특정 섹션만 재생성하는 경우
      if section.present?
        return regenerate_section(section)
      end

      # Step 1: Item Analysis
      item_analysis = run_step("item_analysis") { analyze_items }

      # Step 2: Subskill/Domain Synthesis
      synthesis = run_step("synthesis") { synthesize_domains(item_analysis) }

      # Step 3: Trait Explanation
      trait_explanation = run_step("trait_explanation") { explain_trait }

      # Step 4: Integrated Composer
      integrated = run_step("integrated") { compose_integrated(synthesis, trait_explanation) }

      # Step 5: Book Guidance
      book_guidance = run_step("book_guidance") { generate_book_guidance }

      # Compile all results
      compile_feedback(item_analysis, synthesis, trait_explanation, integrated, book_guidance)
    end

    private

    def run_step(step_name, use_cache: true)
      input_data = build_step_input(step_name)
      input_hash = ResponseCache.compute_hash(input_data)
      model = ENV.fetch("OPENAI_MODEL", "gpt-4o-mini")

      # 캐시 확인
      if use_cache
        cached = @cache.get(@submission.id, step_name, input_hash)
        if cached
          Rails.logger.info("[FeedbackPipeline] 캐시 히트: #{step_name}")
          return cached
        end
      end

      # 새로운 응답 생성
      output = yield

      # 캐시 저장
      @cache.set(@submission.id, step_name, input_hash, output,
                 model: model, prompt_version: PROMPT_VERSION)

      output
    rescue StandardError => e
      Rails.logger.error("[FeedbackPipeline] #{step_name} 실패: #{e.message}")
      @cache.record_failure(@submission.id, step_name, input_hash, e.message,
                           model: model, prompt_version: PROMPT_VERSION)
      fallback_for(step_name)
    end

    def build_step_input(step_name)
      case step_name
      when "item_analysis"
        @submission.responses.pluck(:item_id, :answer_json)
      when "synthesis"
        @submission.metrics_result&.domain_scores_json
      when "trait_explanation"
        @submission.trait_result&.trait_type
      when "integrated"
        @submission.metrics_result&.to_json
      when "book_guidance"
        { trait: @submission.trait_result&.trait_type, metrics: @submission.metrics_result&.id }
      else
        step_name
      end
    end

    def regenerate_section(section)
      # 해당 섹션의 캐시 무효화
      step_map = {
        "executive_summary" => "integrated",
        "item_analysis" => "item_analysis",
        "subskill_synthesis" => "synthesis",
        "trait_explanation" => "trait_explanation",
        "integrated.domain_guidance" => "integrated",
        "integrated.book_guidance" => "book_guidance",
        "integrated.parent_summary" => "integrated"
      }

      step = step_map[section] || section
      @cache.invalidate_step(@submission.id, step)

      # 전체 파이프라인 재실행 (캐시 없이 해당 단계만)
      run
    end

    def analyze_items
      responses = @submission.responses.includes(:item)
      results = @submission.scoring_results.index_by(&:item_id)

      responses.map do |response|
        item = response.item
        scoring = results[item.id]

        {
          item_id: item.id,
          domain: item.domain,
          subskill: item.subskill,
          is_correct: scoring&.is_correct,
          score: scoring&.score,
          max_score: item.points,
          analysis: generate_item_analysis(item, response, scoring)
        }
      end
    end

    def generate_item_analysis(item, response, scoring)
      return fallback_item_analysis(item, scoring) unless api_available?

      # PII 익명화
      student_answer = @pii_redactor.redact(
        response.answer_json.to_s,
        context: { student_name: @student&.name }
      )

      messages = [
        { role: "system", content: "You are an educational assessment analyst. Analyze the student's response briefly in Korean." },
        { role: "user", content: <<~PROMPT }
          문항: #{item.prompt}
          학생 답변: #{student_answer}
          정답 여부: #{scoring&.is_correct ? '정답' : '오답'}
          점수: #{scoring&.score}/#{item.points}

          학생의 이해도를 간략히 분석해주세요 (2-3문장).
          JSON 형식으로 반환: {"analysis": "..."}
        PROMPT
      ]

      result = @client.chat(messages, schema: true)

      # 응답에서 PII 복원 (필요시)
      @pii_redactor.restore(result["analysis"])
    rescue StandardError => e
      Rails.logger.warn("[FeedbackPipeline] 문항 분석 실패: #{e.message}")
      fallback_item_analysis(item, scoring)
    end

    def fallback_item_analysis(item, scoring)
      if scoring&.is_correct
        "학생이 #{item.subskill || item.domain} 영역에 대한 이해를 보여주었습니다."
      else
        "학생이 #{item.subskill || item.domain} 영역에 대한 추가 연습이 필요합니다."
      end
    end

    def synthesize_domains(item_analysis)
      metrics = @submission.metrics_result
      domain_scores = metrics&.domain_scores_json || {}
      subskill_scores = metrics&.subskill_scores_json || {}

      {
        domain_synthesis: domain_scores.map { |domain, score|
          {
            domain: domain,
            score: score,
            summary: generate_domain_summary(domain, score)
          }
        },
        subskill_synthesis: subskill_scores.map { |subskill, score|
          strength = score >= 70 ? "strength" : (score >= 50 ? "developing" : "needs_support")
          {
            subskill: subskill,
            score: score,
            strength: strength,
            label: strength_label(strength)
          }
        }
      }
    end

    def generate_domain_summary(domain, score)
      level = score >= 80 ? "우수한" : (score >= 60 ? "양호한" : "발전 중인")
      domain_kr = domain_label(domain)
      "#{domain_kr} 영역에서 #{level} 수행을 보여주고 있습니다 (#{score}%)."
    end

    def strength_label(strength)
      { "strength" => "강점", "developing" => "발전 중", "needs_support" => "지원 필요" }[strength]
    end

    def domain_label(domain)
      { "decoding" => "해독", "vocabulary" => "어휘", "fluency" => "유창성",
        "comprehension" => "독해", "inference" => "추론" }[domain.to_s] || domain
    end

    def explain_trait
      trait = @submission.trait_result
      return { type: "C", explanation: "독자 유형을 결정할 수 없습니다." } unless trait

      explanation = case trait.trait_type
      when "A"
        "이 학생은 모든 영역에서 우수한 문해력을 보여주고 있습니다. 심화 활동과 고급 읽기 자료가 적합합니다."
      when "B"
        "이 학생은 이해력이 우수하지만, 추론적 사고와 비판적 분석 활동이 도움이 될 것입니다."
      when "C"
        "이 학생은 균형 잡힌 발전을 보이고 있습니다. 특정 영역에 대한 집중 연습이 문해력 기반을 강화할 것입니다."
      when "D"
        "이 학생은 기초 문해력 지원이 필요합니다. 이해 전략과 어휘력 개발에 집중하는 것이 좋습니다."
      else
        "독자 유형 분석 중입니다."
      end

      { type: trait.trait_type, explanation: explanation }
    end

    def compose_integrated(synthesis, trait_explanation)
      {
        executive_summary: generate_executive_summary(synthesis, trait_explanation),
        domain_guidance: generate_domain_guidance(synthesis),
        parent_summary: generate_parent_summary(synthesis, trait_explanation)
      }
    end

    def generate_executive_summary(synthesis, trait)
      domain_summaries = synthesis[:domain_synthesis].map { |d| d[:summary] }.join(" ")
      "#{domain_summaries} 독자 유형: #{trait[:type]}. #{trait[:explanation]}"
    end

    def generate_domain_guidance(synthesis)
      synthesis[:domain_synthesis].to_h do |domain_data|
        guidance = domain_data[:score] >= 70 ?
          "심화 자료로 도전을 계속하세요." :
          "맞춤 연습과 단계별 활동에 집중하세요."

        [domain_data[:domain], { score: domain_data[:score], guidance: guidance }]
      end
    end

    def generate_parent_summary(synthesis, trait)
      scores = synthesis[:domain_synthesis].map { |d| "#{domain_label(d[:domain])}: #{d[:score]}%" }.join(", ")
      "자녀의 문해력 평가 결과: #{scores}. #{trait[:explanation]}"
    end

    def generate_book_guidance
      trait = @submission.trait_result
      metrics = @submission.metrics_result

      # Allowlist에서 도서 후보 가져오기
      service = BookCandidateService.new(@submission)
      candidate_ids = service.generate_candidates

      candidates = BookCatalog.where(id: candidate_ids)
      return { selected_books: [], guidance: "추천 도서가 없습니다." } if candidates.empty?

      # Allowlist 검증
      validator = BookAllowlistValidator.new
      validation = validator.validate_ids(candidate_ids)

      selected = BookCatalog.where(id: validation[:valid_ids]).limit(5)

      BookGuidance.find_or_initialize_by(submission: @submission).update!(
        selected_book_ids_json: selected.map(&:id),
        guidance_json: {
          recommendations: selected.map { |b|
            { id: b.id, title: b.title, author: b.author, reason: book_reason(b, trait) }
          }
        }
      )

      {
        selected_books: selected.map { |b| { id: b.id, title: b.title, author: b.author } },
        guidance: "평가 결과를 바탕으로 지속적인 독서 성장을 위해 다음 도서를 추천합니다."
      }
    end

    def book_reason(book, trait)
      case trait&.trait_type
      when "A" then "도전적인 내용으로 심화 학습에 적합합니다."
      when "B" then "추론 능력 향상에 도움이 됩니다."
      when "C" then "균형 잡힌 독서 경험을 제공합니다."
      when "D" then "기초 이해력 향상에 적합한 수준입니다."
      else "학생의 독서 수준에 맞는 도서입니다."
      end
    end

    def compile_feedback(item_analysis, synthesis, trait_explanation, integrated, book_guidance)
      compiled = {
        executive_summary: integrated[:executive_summary],
        item_analysis: item_analysis,
        subskill_synthesis: synthesis[:subskill_synthesis].to_h { |s| [s[:subskill], s] },
        trait_explanation: trait_explanation[:explanation],
        integrated: {
          domain_guidance: integrated[:domain_guidance],
          parent_summary: integrated[:parent_summary],
          book_guidance: book_guidance
        }
      }

      AiFeedbackCompiled.find_or_initialize_by(submission: @submission).update!(
        compiled_json: compiled
      )

      compiled
    end

    def fallback_for(step_name)
      case step_name
      when "item_analysis" then []
      when "synthesis" then { domain_synthesis: [], subskill_synthesis: [] }
      when "trait_explanation" then { type: "C", explanation: "분석 대기 중입니다." }
      when "integrated" then { executive_summary: "보고서 생성 대기 중입니다.", domain_guidance: {}, parent_summary: "" }
      when "book_guidance" then { selected_books: [], guidance: "" }
      else {}
      end
    end

    def api_available?
      ENV["OPENAI_API_KEY"].present?
    end
  end
end
