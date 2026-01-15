# 시스템/애플리케이션 설계서 (System/Application Design)

## 1. 아키텍처 개요
- 구성: Web Frontend + API Backend + Worker(Scoring/LLM/Report/Analytics) + DB + Object Storage(PDF) + Queue(Event Bus)
- 핵심: 제출 이벤트 기반 비동기 파이프라인

## 2. 주요 컴포넌트

### 2.1 Frontend(Web)
- Admin Console: 문항/도서 allowlist 관리
- SchoolManager Portal: 학생 계정 관리, 학교 보고서
- Teacher Portal: 검사 운영, 학생 기록, 피드백 워크스페이스, 보고서 생성/공유
- Student/Parent Portal: 보고서 열람/다운로드

### 2.2 Backend(API)
- Auth/RBAC
- ItemBank(지문/문항/정답/루브릭/버전)
- Assessment Session(세션/배부/정책)
- Response(응답 저장/제출)
- Scoring & Metrics(채점/지표)
- Trait Rules(성향 유형 규칙 판정)
- LLM Orchestrator(OpenAI 호출, 스키마 검증, 캐시)
- Book Catalog(Allowlist) + Candidate Builder + Enforcer
- Feedback Workspace(교사 편집/승인/감사로그)
- Report Service(템플릿 렌더링, PDF 저장, 접근 제어)
- Analytics(집계/학교 보고서 데이터셋)

### 2.3 Workers
- pipeline-worker: 제출 이벤트 처리(채점→LLM→도서지도→보고서)
- report-worker: HTML→PDF 렌더, 차트 렌더
- analytics-worker: 집계 갱신 및 학교 보고서 준비

## 3. 이벤트/파이프라인(개인 보고서)

### 3.1 Trigger
- `submission.completed(submission_id)` 발행

### 3.2 Steps (권장)
1) Score & Metrics (규칙 기반)
2) LLM Step1: Item Analyzer(문항별)
3) LLM Step2: Subskill/Domain Synthesis(하위지표/영역)
4) Trait Rules + LLM Step3: Trait Explanation(유형 고정)
5) LLM Step4: Integrated Composer(통합 요약/지도/학부모 요약)
6) Book Candidate Builder(allowlist 기반) + LLM Book-only Guidance + Enforcer
7) Draft Report Render(정책에 따라 ‘초안’ 표시)
8) Teacher Review & Approve(수동)
9) Final Report Render(AI+교사 병합) + Publish Access

## 4. 교사 첨삭/승인과 보고서 병합

### 4.1 상태
- AI: generated
- Teacher feedback: Draft / Approved(locked)
- Report: Draft / Final

### 4.2 병합 규칙
- 최종 본문: teacher(Approved) 우선
- 결측 항목: AI fallback(옵션)
- AI 초안은 참고 섹션으로 포함 가능(정책)

## 5. 추천 도서 Allowlist 강제
- 후보 생성: allowlist에서만 조회
- LLM 입력: 후보(book_id + 메타)만 제공
- LLM 출력: selected_book_ids(book_id 배열만)
- Enforcer: 후보 포함 여부 검증, 위반 시 재시도→대체

## 6. 보고서 배포
- 웹 뷰어: 권한 확인 후 렌더/스트리밍
- 다운로드: signed URL 발급(짧은 TTL)
- 학부모 링크: report_access 토큰 기반, 만료/회수 가능

## 7. 관측/운영
- LLM 비용/실패율/스키마 위반율/지연시간
- 보고서 생성/다운로드 감사 로그
