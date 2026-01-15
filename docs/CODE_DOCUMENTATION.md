# 소스코드 문서화 (Code Documentation)

## 1. 문서 구조(/docs)
- REQUIREMENTS.md : 요구사항 정의서
- SYSTEM_DESIGN.md : 시스템/애플리케이션 설계서
- DATABASE_DESIGN_ERD.md : DB 설계서(ERD)
- CODE_DOCUMENTATION.md : 코드 문서화 가이드(본 문서)
- TEST_PLAN_REPORT.md : 테스트 계획서/결과서
- USER_MANUAL.md : 사용자 매뉴얼
- TEACHER_FEEDBACK_UI_SPEC.md : 교사 첨삭 UI 상세
- REPORT_SPEC.md : 보고서 항목/매핑
- TASKS.md : 개발 작업 체크리스트

## 2. 코드 레벨 문서화 원칙
- 모듈 단위 README 포함(책임/입력/출력/권한/에러)
- LLM 관련:
  - prompts/에 프롬프트 버전 관리
  - schemas/에 JSON 스키마 관리
  - 모든 LLM 결과는 output_validator 통과 전 반영 금지
- 보고서:
  - report-templates/에 템플릿 버전 관리
  - 병합 규칙 엔진은 단위 테스트 필수

## 3. 주석/표준(권장)
- 함수/클래스 주석: 목적, 파라미터, 반환, 예외
- API 핸들러: 권한(roles), 입력 검증(schema), 응답 DTO 명시
- 워커 작업: idempotency 키(input_hash 등), 재시도 정책, 실패 fallback 설명

## 4. 핵심 모듈 문서화 대상
- RBAC 정책 테이블/미들웨어
- LLM Orchestrator(단계/캐시/스키마/가드레일)
- allowlist_books_enforcer(규정 위반 방지)
- teacher_feedback versioning/approval/lock
- report renderer(HTML→PDF), signed URL 발급
