# 데이터베이스 설계서 (Database Design - ERD)

## 1. 엔티티 목록(핵심)

### 사용자/권한
- users(id, role, status, name, email_optional, created_at)
- schools(id, name)
- classes(id, school_id, grade, name)
- student_profiles(student_id, school_id, class_id, student_code, pii_ref_id_nullable)
- parent_links(id, parent_user_id, student_id, access_token, expires_at)

### 문항/검사
- passages(id, title, text, grade_band, tags_json)
- items(id, passage_id, type, domain, subskill, difficulty, prompt, choices_json, answer_key_json, rubric_json, points)
- assessment_versions(id, name, status, published_at)
- assessment_version_items(version_id, item_id, order_no)

### 검사 세션/응답
- sessions(id, school_id, class_id, version_id, created_by_teacher_id, start_at, end_at, status, access_code)
- submissions(id, session_id, student_id, started_at, submitted_at, status)
- responses(id, submission_id, item_id, answer_json, time_spent, updated_at)

### 채점/지표/성향
- scoring_results(id, submission_id, item_id, score, is_correct, rubric_breakdown_json)
- metrics_results(id, submission_id, domain_scores_json, subskill_scores_json, percentile_json, computed_at)
- trait_results(id, submission_id, trait_type, trait_scores_json, computed_at)

### LLM 산출물
- ai_feedback_runs(id, submission_id, step, model, prompt_version, input_hash, output_json, status, created_at)
- ai_feedback_compiled(id, submission_id, compiled_json, created_at)

### 교사 피드백/감사
- teacher_feedback(id, submission_id, editor_teacher_id, content_json, diff_json, status[draft|approved], approved_at, updated_at)
- feedback_audit(id, teacher_feedback_id, action, actor_id, timestamp, meta_json)

### 보고서/접근
- reports(id, scope[student|school], submission_id_nullable, session_id_nullable, version, status[draft|final], template_version, storage_key, created_at)
- report_access(id, report_id, subject_user_id_nullable, access_token_nullable, can_view, can_download, expires_at)

### 도서 Allowlist/지도
- book_catalog(id, isbn, title, author, grade_band, difficulty, tags_json, active)
- book_candidates(id, submission_id, candidate_book_ids_json, generated_at)
- book_guidance(id, submission_id, selected_book_ids_json, guidance_json, created_at)

### 집계(권장 분리)
- analytics_domain_agg(session_id, class_id_nullable, domain, avg, std, dist_json, updated_at)
- analytics_subskill_agg(session_id, subskill, avg, dist_json, updated_at)
- analytics_trait_agg(session_id, trait_type, ratio, updated_at)

---

## 2. 관계(요약)
- schools 1—N classes
- classes 1—N sessions
- sessions 1—N submissions
- submissions 1—N responses / scoring_results / metrics_results / trait_results / ai_feedback_runs / teacher_feedback / reports(student)
- sessions 1—N reports(school)
- assessment_versions N—N items (assessment_version_items)
- book_catalog(allowlist) → book_candidates → book_guidance

---

## 3. 설계 포인트
- PII 최소화: student_profiles는 내부 식별자 중심, 필요 시 pii_ref_id로 분리(암호화 테이블 권장)
- 재현성: teacher_feedback 승인본 + ai_feedback_runs(버전) + template_version으로 report.version 생성
- 감사: feedback_audit 및 report_access 로그(다운로드 포함) 권장
- 인덱스: submissions(session_id, student_id), responses(submission_id), scoring_results(submission_id), reports(scope, submission_id/session_id)
