# 🚀 하네스_해커톤_v1 (Test-harness-hackathon)

> **Spring Boot 3 (Java 21) + Google Antigravity 1인 단기 해커톤 전용 에이전트 하네스**  
> Spring 내부 동작에 익숙하지 않은 상태에서도 AI 에이전트에게 **기획 분해 → 코드 구현 → 데모 데이터 시딩 → 고속 컴파일·런타임 검증 → Git 체크포인트**까지 자율적으로 맡기고 24~48시간 내에 프로토타입을 완주하기 위해 설계된 템플릿입니다.

---

## 1. 설계 목적 (Why This Harness?)

단기 해커톤에서 AI 코딩 에이전트로 Spring Boot 백엔드를 개발할 때 가장 자주 발생하는 **4가지 실패 원인**을 구조적으로 차단하는 것이 이 하네스의 핵심 목적입니다.

1. **초보자 함정 원천 차단 (Easy-Spring Mode)**
   - JPA 연관관계(`@OneToMany`, `@ManyToOne` 등)로 인한 무한 순환참조와 `LazyInitializationException`, 그리고 `Spring Security` 설정 늪으로 인해 개발이 멈추는 현상을 막기 위해 **단순 ID 참조(`Long xxxId`)**와 **Java 21 `record` DTO**만 사용하도록 에이전트 규칙 및 정적 검사기로 강제합니다.
2. **골든 샘플 복제 기반의 일관된 코드 생성 (Golden Sample Pattern)**
   - 에이전트가 매번 다른 패키지 구조나 어노테이션을 혼용하지 않도록, 완벽히 동작하는 표준 CRUD 1세트(`sample/` 패키지)를 **골든 샘플**로 제공하고 모든 신규 도메인을 이 패턴 그대로 복제해 구현하도록 유도합니다.
3. **에이전트 자율 검증 및 자가 치유 루프 (Closed-Loop Verification)**
   - 에이전트가 코드만 작성하고 검증을 사람에게 떠넘기지 않도록, **1~2초 초고속 컴파일 검사(`verify-fast.sh`) → 8080 포트 좀비 프로세스 정리 및 재기동(`server-ctl.sh`) → 실제 API 호출 테스트(`smoke-test.sh`) → 에러 발생 위치(`파일명:줄번호`) 자동 역추적**까지 스스로 수행하게 만듭니다.
4. **심사위원 데모 시연 최우선 설계 (Demo-First Architecture)**
   - 별도 DB 설치 없이도 서버 재시작 후 데이터가 유지되는 **H2 로컬 파일 모드(`./data/hackathon-db`)**, 서버 기동 시 데모용 더미 데이터를 자동 삽입하는 **`DataInitializer`**, 프론트엔드 없이도 브라우저에서 즉시 시연 가능한 **한글 Swagger UI(`/swagger`)**를 기본 내장했습니다.

---

## 2. 핵심 아키텍처 및 5대 방어 장치

| 계층 | 주요 구성 파일 | 설계 방식 및 역할 |
| :--- | :--- | :--- |
| **① 에이전트 규칙 계층** | `GEMINI.md`<br>`.agents/rules/easy-spring.md`<br>`.agents/rules/conventions-and-git.md`<br>`.agents/rules/testing-and-runtime.md` | • JPA 연관관계 및 Spring Security 추가 금지<br>• 평면 패키지(`com.hackathon.app.<도메인>`), `/api/v1/케밥-케이스`, 한글 Swagger 강제<br>• 단일 `main` 브랜치 및 `<타입>: <한글 요약>` Git 커밋 규칙 정의 |
| **② 슬래시 워크플로우** | `.agents/workflows/spec.md` (`/spec`)<br>`.agents/workflows/implement-api.md` (`/implement-api`)<br>`.agents/workflows/debug-runtime.md` (`/debug-runtime`)<br>`.agents/workflows/handoff.md` (`/handoff`) | • `/spec`: 아이디어를 테이블 설계(`SPEC.md`)와 15분 단위 태스크(`TASKS.md`)로 분해<br>• `/implement-api`: 골든 샘플 복제 → 시딩 추가 → 검증 → 서버 재기동 → 커밋 자동화<br>• `/debug-runtime`: `logs/server.log` 기반 런타임 에러 자가 수정<br>• `/handoff`: 대화창 컨텍스트 과부하 방지를 위한 세션 상태 스냅샷 인계 |
| **③ 고속 검증 & 제어기** | `scripts/verify-fast.sh`<br>`scripts/server-ctl.sh`<br>`scripts/smoke-test.sh`<br>`scripts/checkpoint.sh` | • `verify-fast.sh`: 금지 어노테이션(`@ManyToOne`, `*ServiceImpl`) 적발 및 2초 내 컴파일 체크<br>• `server-ctl.sh`: 8080 포트 점유 좀비 프로세스 자동 `kill -9` 후 백그라운드 기동 및 Health 폴링<br>• `checkpoint.sh`: 커밋 접두사(`feat:` 등) 자동 보정 및 실패 시 원클릭 롤백(`--rollback`) |
| **④ 공통 인프라 모듈** | `common/ApiResponse.java`<br>`common/GlobalExceptionHandler.java`<br>`common/DataInitializer.java`<br>`common/CorsConfig.java` | • `GlobalExceptionHandler`: 에러 발생 시 프로젝트 내부 파일명·줄번호(`location`)를 JSON으로 반환해 에이전트 즉시 수정 지원<br>• `DataInitializer`: DB가 비어 있으면 시연용 초기 데이터를 자동 시딩<br>• `CorsConfig`: 웹/모바일 프론트엔드 연동 시 모든 CORS 에러 사전 차단 |
| **⑤ 골든 샘플 템플릿** | `sample/SampleItem.java`<br>`sample/SampleItemRepository.java`<br>`sample/SampleItemService.java`<br>`sample/SampleItemController.java` | • 에이전트가 신규 도메인 코드를 작성할 때 그대로 참고·복제하는 표준 CRUD 레퍼런스 |

---

## 3. 원클릭 초기 세팅 (Quick Start — 1분 완성)

1. **IntelliJ IDEA**에서 `New Project` → `Spring Boot`를 선택하고 **Type: Gradle - Groovy**, **Java: 21**로 빈 프로젝트를 생성합니다. (의존성은 스크립트가 자동으로 채워주므로 선택하지 않아도 됩니다.)
2. 프로젝트 루트 터미널(Windows는 `Git Bash` 권장)에서 아래 명령어 한 줄을 실행합니다:

```bash
curl -fsSL [https://raw.githubusercontent.com/iamdudumon/Test-harness-hackathon/main/bootstrap-harness.sh](https://raw.githubusercontent.com/iamdudumon/Test-harness-hackathon/main/bootstrap-harness.sh) | bash
```

3. IntelliJ 우측 상단의 **Load Gradle Changes(코끼리 아이콘)**를 눌러 의존성을 동기화합니다.
4. **Google Antigravity**에서 해당 프로젝트 폴더를 열고 바로 개발을 시작합니다.

---

## 4. 해커톤 실전 4단계 사용 루프

### Step 1. 기획 및 태스크 분해 (`/spec`)
Antigravity 채팅창에 만들고 싶은 서비스 아이디어를 입력합니다.
```text
/spec 대학생 스터디 모임 매칭 및 출석 인증 서비스
```
- 에이전트가 코드를 바로 짜지 않고, 단순 ID 참조 기반의 엔티티 설계서(`docs/SPEC.md`)와 15분 단위 구현 체크리스트(`docs/TASKS.md`)를 먼저 생성합니다.

### Step 2. 원스톱 기능 구현 (`/implement-api`)
체크리스트가 마음에 들면 아래 슬래시 명령어만 반복해서 입력합니다.
```text
/implement-api
```
- 에이전트가 `TASKS.md`의 다음 미완료 항목 1개를 읽고 **코드 구현 → `DataInitializer` 시딩 데이터 추가 → `verify-fast.sh` 컴파일 체크 → `server-ctl.sh restart` 재기동 → `smoke-test.sh` 호출 확인 → `checkpoint.sh` Git 커밋**까지 한 번에 완료합니다.
- 완료 후 브라우저에서 `http://localhost:8080/swagger`를 열어 한글로 정리된 API를 즉시 테스트합니다.

### Step 3. 런타임 에러 자가 치유 (`/debug-runtime`)
API 호출 중 500 에러가 나거나 DB 스키마 충돌이 발생하면 아래 명령어를 입력합니다.
```text
/debug-runtime
```
- 에이전트가 `./logs/server.log`와 에러 응답 JSON의 `error.location`을 읽고 원인을 찾아 수정하거나, 필요 시 `./scripts/server-ctl.sh reset-db`로 로컬 H2 DB를 깨끗하게 초기화 후 재시딩합니다.

### Step 4. 대화창 리셋 및 세션 인계 (`/handoff`)
기능 2~3개를 구현해 대화가 길어지면 에이전트 속도와 정확도를 유지하기 위해 세션을 리셋합니다.
```text
/handoff
```
- 에이전트가 현재 구현 상태와 다음 할 일을 `docs/TASKS.md` 상단(`Current Session State`)에 요약해 커밋하고, **새 대화창(New Conversation)**에 붙여넣을 시작 프롬프트 한 줄을 출력해 줍니다.

---

## 5. 생성되는 디렉토리 구조

```text
.
├── GEMINI.md                        # 전역 에이전트 행동 지침 및 Easy-Spring 절대 규칙
├── build.gradle                     # Spring Boot 3.3.x + Java 21 + H2 + Springdoc OpenAPI
├── .agents/
│   ├── rules/
│   │   ├── easy-spring.md           # JPA 연관관계/Security 금지 및 골든 샘플 복제 규칙
│   │   ├── conventions-and-git.md   # 경량 네이밍/URI/Swagger 및 Git 커밋 컨벤션
│   │   └── testing-and-runtime.md   # 고속 검증 및 서버 제어 규칙
│   ├── workflows/
│   │   ├── spec.md                  # /spec : 기획 및 태스크 분해
│   │   ├── implement-api.md         # /implement-api : 구현 + 시딩 + 검증 + 체크포인트
│   │   ├── debug-runtime.md         # /debug-runtime : server.log 분석 및 자가 수정
│   │   └── handoff.md               # /handoff : 새 대화창 전환용 상태 스냅샷 기록
│   └── skills/
│       └── api-smoke-test/SKILL.md  # 로컬 API 상태 확인 및 curl 스모크 테스트 스킬
├── docs/
│   ├── SPEC.md                      # 도메인 엔티티 및 API 명세 (Single Source of Truth)
│   └── TASKS.md                     # 구현 체크리스트 및 세션 핸드오프 상태 보드
├── scripts/
│   ├── server-ctl.sh                # 8080 포트 좀비 프로세스 정리 & 백그라운드 서버 제어
│   ├── verify-fast.sh               # 1~2초 초고속 컴파일 & 금지 패턴 정적 검사
│   ├── smoke-test.sh                # 로컬 API curl 호출 및 에러 로그 자동 출력
│   └── checkpoint.sh                # 커밋 접두사 자동 보정 & 원클릭 롤백(--rollback)
└── src/main/
    ├── resources/application.yml    # H2 로컬 파일 DB + Swagger(/swagger) + 파일 로깅
    └── java/com/hackathon/app/
        ├── HackathonApplication.java
        ├── common/                  # ApiResponse, GlobalExceptionHandler, CorsConfig, DataInitializer
        └── sample/                  # 에이전트가 복제할 표준 CRUD 골든 샘플 1세트
```
