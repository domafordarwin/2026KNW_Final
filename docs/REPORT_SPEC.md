# REPORT_SPEC: 보고서 항목 정의 및 데이터 매핑(학생/학교)

## 0. 공통 원칙

- 보고서는 2종: `학생별 보고서(Student Report)` + `학교 전체 보고서(School Report)`
- 온라인 열람(HTML/PDF Viewer) + PDF 다운로드(signed URL) 제공
- AI 분석은 항목별 처리→통합 합성 결과를 JSON으로 저장하고 템플릿에 주입한다.
- 교사 피드백은 AI 초안을 검수·수정한 후 승인(Approve)하면 최종 보고서에 우선 반영한다.
- 추천 도서/지도안은 **allowlist(book_catalog)** 기반으로만 생성한다.

---

## 1. 보고서 스코프 및 출력 버전

### 1.1 스코프
- Student Report: `submission_id` 기준(개인)
- School Report: `session_id` 기준(학교/학급 집계)

### 1.2 버전 고정(재현성)
- report_version은 다음을 포함하여 식별한다.
  - assessment_version_id
  - template_version
  - ai_prompt_version set
  - ai_model_version set
  - teacher_feedback_approved_at (있을 경우)

---

## 2. 학생별 보고서(Student Report) 섹션 매핑

> 표기 규칙  
> - AI 초안: `ai_feedback_*`  
> - 교사본: `teacher_feedback.content_json` (승인본 우선)  
> - 점수/지표: `metrics_results`, `scoring_results`  
> - 도서: `book_catalog`, `book_candidates`, `book_guidance`

| 섹션 ID | 섹션명 | 데이터 소스(예시) | 생성 로직 | 검증/가드레일 |
|---|---|---|---|---|
| S-01 | 표지/기본정보 | students, classes, sessions | 학생/세션 메타 렌더 | PII 최소표시 정책 |
| S-02 | 검사 개요 | assessment_versions, version_items | 검사 구성(영역/문항수) 요약 | 버전 스냅샷 고정 |
| S-03 | 핵심 요약 | AI: compiled.executive_summary / Teacher: executive_summary | 교사 승인본 우선, AI 참고/대체 정책 적용 | 낙인/단정 표현 필터 |
| S-04 | 영역 프로파일(차트) | metrics_results.domain_scores_json, percentile_json | 영역별 점수/백분위/등급 산출 및 차트 | 결측/0점 규칙 |
| S-05 | 하위지표 강·약점 | metrics_results.subskill_scores_json + subskill_synthesis | TOP N 추출 + 설명 + 과제 제안 | 근거 문항 id 링크 |
| S-06 | 문항 기반 심층분석(표) | responses, scoring_results, item_analysis | 문항별 오류유형/미니 피드백 표 생성 | 문항-응답 매칭 무결성 |
| S-07 | 서술형 피드백(선택) | rubric_breakdown_json + item_analysis | 루브릭 요소별 개선 포인트 | 과도한 확정 표현 제한 |
| S-08 | 독자성향(유형/해석) | trait_results.trait_type + trait_explanation | 유형은 규칙 고정, 해석 문장만 편집 가능 | 유형 임의변경 금지(권장) |
| S-09 | 개인 지도 방향(영역별) | integrated.domain_guidance + teacher.domain_guidance | 교사 승인본 우선 + AI 참고 | 승인 없으면 ‘초안’ 표시 |
| S-10 | 추천 도서 기반 지도안 | book_candidates, book_guidance, book_catalog + 교사편집 | allowlist 후보 내 선택 + 활동/질문 생성 | 목록 외 도서 금지 |
| S-11 | 학부모 요약 | integrated.parent_summary + teacher.parent_summary | 문장 길이/난이도 제한 템플릿 | 민감/낙인 표현 필터 |
| S-12 | 부록(근거) | reference metadata | 교사용 옵션(학생/학부모용 숨김 가능) | PII/식별 제거 |

### 2.1 섹션 병합 규칙(필수)
- 기본:
  - `teacher_feedback (Approved)` > `teacher_feedback (Draft)` > `ai_feedback`
- 옵션:
  - 교사 승인본이 없는 섹션은 AI로 자동 채움(fallback)
  - 학생/학부모용에서 AI 참고 섹션 노출 여부는 정책으로 제어

---

## 3. 학교 전체 보고서(School Report) 섹션 매핑

| 섹션 ID | 섹션명 | 데이터 소스(예시) | 생성 로직 | 검증/가드레일 |
|---|---|---|---|---|
| C-01 | 조사 개요 | sessions, assessment_versions | 대상/기간/버전 요약 | 개인 식별 제거 |
| C-02 | 참여/제출 현황 | submissions 집계 | 학급/학년별 제출률 | 수치 불일치 탐지 |
| C-03 | 영역별 결과 분포 | analytics.domain_agg | 평균/분산/분포 차트 | 소표본 경고 |
| C-04 | 하위지표 TOP 취약 | analytics.subskill_agg | TOP N + 개선 우선순위 | 근거 지표 링크 |
| C-05 | 성향(A~D) 분포 | analytics.trait_agg | 유형 비율 + 유형별 지도 포인트 | 개인 식별 금지 |
| C-06 | 종합 인사이트 | ai_feedback_runs(school_synthesis) | 집계 통계 기반 합성 | PII redaction + schema |
| C-07 | 운영/프로그램 제안 | 템플릿 + (선택) LLM | 4주/8주 실행안 | 과도한 단정 제한 |

---

## 4. 도서 Allowlist 정책(강제)

### 4.1 원칙
- 추천 도서/지도안 생성은 반드시 `book_catalog(active=true)`에서 제공된 후보에 근거한다.
- LLM 출력은 **book_id 배열만 허용**한다(제목 자유 생성 금지).

### 4.2 검증 규칙
- `selected_book_ids`가 후보 목록에 포함되는지 검증
- 위반 시
  1) 재시도(“목록 외 추천 금지” 강화 지시)
  2) 반복 실패 시 규칙 기반 추천(필터/정렬)으로 대체

---

## 5. 리포트 생성/배포 규칙

- 생성 트리거:
  - 학생 보고서: 제출 완료 + (정책) 교사 승인 완료 후 자동 생성 또는 수동 생성
  - 학교 보고서: 세션 종료 후 수동/스케줄 생성
- 저장:
  - PDF는 object storage 저장 후 storage_key 등록
- 배포:
  - 웹뷰어: 권한 확인 후 스트리밍/표시
  - 다운로드: signed URL(TTL) 발급 후 제공
