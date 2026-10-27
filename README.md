# 🚀 하네스_해커톤_v1.1 (Test-harness-hackathon)

> **Spring Boot 3 (Java 21) + Google Antigravity 1인 단기 해커톤 전용 에이전트 하네스 (Lean Edition)**  
> Spring 내부 동작에 익숙하지 않은 상태에서도 AI 에이전트에게 **기획 분해 → 코드 구현 → 데모 데이터 시딩 → 고속 컴파일·런타임 검증 → 자가 치유 → Git 체크포인트**까지 자율적으로 맡기고 24~48시간 내에 프로토타입을 완주하기 위해 설계된 방어형 백엔드 템플릿입니다.

---

## 1. 설계 목적 (Why This Harness?)

단기 해커톤에서 AI 코딩 에이전트로 Spring Boot 백엔드를 개발할 때 가장 자주 발생하는 **4가지 실패 원인**을 프롬프트와 물리적 스크립트(Guardrail)로 동시에 차단합니다.

1. **초보자 함정 원천 차단 (Easy-Spring Mode)**
   - JPA 연관관계(`@OneToMany`, `@ManyToOne`, `@JoinColumn` 등)로 인한 무한 순환참조·`LazyInitializationException`과 `Spring Security` 설정 늪으로 인해 개발이 멈추는 현상을 막기 위해 **단순 ID 참조(`Long xxxId`)**와 **Java 21 `record` DTO**만 사용하도록 에이전트 규칙 및 정적 검사기(`verify-fast.sh`)로 강제합니다.
2. **골든 샘플 복제 기반의 일관된 코드 생성 (Golden Sample Pattern)**
   - 에이전트가 매번 다른 패키지 구조나 어노테이션을 혼용하지 않도록, 완벽히 동작하는 표준 CRUD(`GET`/`POST`/`PUT`/`DELETE`) 1세트(`sample/` 패키지)를 **골든 샘플**로 제공하고 모든 신규 도메인을 이 패턴 그대로 복제해 구현하도록 유도합니다.
3. **에이전트 자율 검증 및 자가 치유 루프 (Closed-Loop Verification)**
   - 에이전트가 코드만 작성하고 검증을 사람에게 떠넘기지 않도록 **정적 규칙 검사 및 고속 컴파일(`verify-fast.sh`, 캐시 히트 시 1~2초 · 코드 변경 시 수 초) → 8080 포트 Java 좀비 프로세스 안전 정리 및 재기동(`server-ctl.sh`) → 실제 API 호출 테스트(`smoke-test.sh`) → 에러 발생 위치(`파일명:줄번호`) 자동 역추적**까지 스스로 수행하게 만듭니다.
4. **심사위원 데모 시연 최우선 설계 (Demo-First Architecture)**
   - 별도 DB 설치 없이도 서버 재시작 후 데이터가 유지되는 **H2 로컬 파일 모드(`./data/hackathon-db`)**, 서버 기동 시 데모용 더미 데이터를 자동 삽입하는 **`DataInitializer`**, 프론트엔드 없이도 브라우저에서 즉시 시연 가능한 **한글 Swagger UI(`/swagger`)**를 기본 내장했습니다.

---

## 2. 핵심 아키텍처 및 5대 방어 장치

v1.1에서는 에이전트의 컨텍스트 토큰 낭비를 줄이기 위해 중복 규칙과 문서를 단일화하고, 스크립트의 OS 호환성과 정적 방어력을 강화했습니다.

| 계층 | 주요 구성 파일 | 설계 방식 및 역할 |
| :--- | :--- | :--- |
| **① 에이전트 규칙 계층** | `GEMINI.md`<br>`.agents/rules/core-rules.md` | • 중복 문서를 압축하여 매 턴 소모되는 시스템 프롬프트 토큰 절감<br>• JPA 연관관계, `Spring Security`, `*ServiceImpl`, Lombok `@Data`/`@Builder` 전면 금지<br>• 평면 패키지(`com.hackathon.app.<도메인>`), `/api/v1/케밥-케이스`, 한글 Swagger 강제 |
| **② 슬래시 워크플로우** | `.agents/workflows/spec.md` (`/spec`)<br>`.agents/workflows/implement-api.md` (`/implement-api`)<br>`.agents/workflows/debug-runtime.md` (`/debug-runtime`)<br>`.agents/workflows/handoff.md` (`/handoff`) | • `/spec`: 아이디어를 통합 설계·태스크 보드(`docs/PLAN.md`) 한 파일로 분해<br>• `/implement-api`: 골든 샘플 복제 → 시딩 추가 → 검증 → 서버 재기동 → 스모크 테스트(실패 시 자가 수정) → 커밋 원스톱 자동화<br>• `/debug-runtime`: `logs/server.log` 및 `error.location` 기반 런타임 에러 자가 복구<br>• `/handoff`: 대화창 컨텍스트 과부하 방지를 위한 세션 상태 스냅샷 인계 |
| **③ 고속 검증 & 제어기** | `scripts/verify-fast.sh`<br>`scripts/server-ctl.sh`<br>`scripts/smoke-test.sh`<br>`scripts/checkpoint.sh` | • `verify-fast.sh`: 금지 어노테이션·Security 의존성 적발 및 Gradle Daemon 컴파일 체크(캐시 히트 시 1~2초, 코드 변경 시 수 초)<br>• `server-ctl.sh`: Windows(Git Bash) & Mac/Linux 호환. 8080 포트를 점유한 **Java 프로세스만** 종료(무관한 프로세스는 건너뜀)하고 백그라운드 기동·Health 폴링(최대 60초), `PORT` 환경변수로 포트 변경 가능<br>• `checkpoint.sh`: 커밋 접두사(`feat:` 등) 자동 보정 및 작업 상태 감지형 스마트 롤백(`--rollback`, 롤백 직전 stash/태그 자동 백업) |
| **④ 공통 인프라 모듈** | `common/ApiResponse.java`<br>`common/GlobalExceptionHandler.java`<br>`common/DataInitializer.java`<br>`common/CorsConfig.java`<br>`common/OpenApiConfig.java` | • `ApiResponse`: `@JsonInclude(NON_NULL)` 기반의 깔끔한 공통 응답 래퍼<br>• `GlobalExceptionHandler`: 에러 발생 시 프로젝트 내부 파일명·줄번호(`location`)를 JSON으로 반환해 에이전트 즉시 수정 지원(404/405/415·잘못된 JSON 등 클라이언트 오류는 500이 아닌 원래의 4xx로 응답, 앱 코드 위치가 없으면 `location` 생략)<br>• `DataInitializer`: DB가 비어 있으면 시연용 초기 데이터를 자동 시딩<br>• `CorsConfig`: 웹/모바일 프론트엔드 연동 시 모든 CORS 에러 사전 차단 |
| **⑤ 골든 샘플 템플릿** | `sample/SampleItem.java`<br>`sample/SampleItemRepository.java`<br>`sample/SampleItemService.java`<br>`sample/SampleItemController.java` | • 에이전트가 신규 도메인 코드를 작성할 때 그대로 참고·복제하는 표준 CRUD(`GET` 목록/단건, `POST` 생성, `PUT` 더티 체킹 수정, `DELETE` 삭제) 레퍼런스 |

---

## 3. 원클릭 초기 세팅 (Quick Start — 1분 완성)

1. **IntelliJ IDEA**에서 `New Project` → `Spring Boot`를 선택하고 **Type: Gradle - Groovy**, **Java: 21**로 빈 프로젝트를 생성합니다. *(의존성은 스크립트가 `build.gradle`에 자동으로 채워주므로 선택하지 않아도 됩니다.)*
2. 프로젝트 루트 터미널(Windows는 **Git Bash** 권장, Mac/Linux는 기본 터미널)에서 아래 명령어 한 줄을 실행합니다:

```bash
curl -fsSL https://raw.githubusercontent.com/iamdudumon/Test-harness-hackathon/main/bootstrap-harness.sh | bash
```

> ⚠️ **덮어쓰기 보호**: 이미 하네스가 설치된 프로젝트(`docs/PLAN.md` 또는 `common/`·`sample/` 패키지 존재)에서 다시 실행하면 작성 중인 코드와 `docs/`가 삭제되므로 스크립트가 경고 후 중단합니다. 정말 덮어쓰려면 `curl -fsSL <URL> | FORCE=1 bash` 또는 `FORCE=1 ./bootstrap-harness.sh`로 실행하세요.  
> `./gradlew`가 없는 빈 폴더라면 시스템에 `gradle`이 있을 때 wrapper(8.10.2)를 자동 생성합니다.

3. IntelliJ 우측 상단의 **Load Gradle Changes(코끼리 아이콘)**를 눌러 의존성을 동기화합니다.
4. 터미널에서 초기 검증 및 서버 기동을 한 번 실행해 정상 동작을 확인합니다:

```bash
./scripts/verify-fast.sh && ./scripts/smoke-test.sh
```

5. **Google Antigravity**에서 해당 프로젝트 폴더를 열고 바로 해커톤 개발을 시작합니다.

---

## 4. 해커톤 실전 4단계 사용 루프

### Step 1. 기획 및 태스크 분해 (`/spec`)
Antigravity 채팅창에 만들고 싶은 서비스 아이디어를 입력합니다.
```text
/spec 대학생 스터디 모임 매칭 및 출석 인증 서비스
```
- 에이전트가 코드를 바로 짜지 않고, 단순 ID 참조 기반의 엔티티 설계표와 핵심 API 명세, 15분 단위 구현 체크리스트를 **`docs/PLAN.md` 단일 파일**에 생성하고 첫 체크포인트 커밋을 남깁니다.

### Step 2. 원스톱 기능 구현 (`/implement-api`)
`docs/PLAN.md`의 기획이 마음에 들면 아래 슬래시 명령어만 반복해서 입력합니다.
```text
/implement-api
```
- 에이전트가 `docs/PLAN.md`의 다음 미완료 항목(`[ ]`) 1개를 읽고 아래 과정을 자율적으로 완수합니다:
  1. `sample/` 골든 샘플을 복제하여 신규 도메인(`Entity`, `Repository`, `Service` + `record` DTO, `Controller`) 작성
  2. `DataInitializer.java`에 데모 시연용 초기 데이터 3건 이상 추가
  3. `./scripts/verify-fast.sh`로 금지 패턴 및 컴파일 에러 고속 검증(변경이 없으면 1~2초, 코드 수정 시 수 초)
  4. `./scripts/server-ctl.sh restart`로 좀비 프로세스 정리 후 서버 재기동
  5. `./scripts/smoke-test.sh`로 실제 API 호출 검증(조회는 `GET`, 생성·수정·삭제는 `POST|PUT|DELETE` + JSON 본문) *(에러 발생 시 로그와 `error.location`을 읽고 스스로 수정 후 재검증)*
  6. `docs/PLAN.md` 진행 상태 갱신 및 `./scripts/checkpoint.sh`로 Git 커밋 완료
- 완료 보고를 받으면 브라우저에서 `http://localhost:8080/swagger`를 열어 한글로 정리된 API를 즉시 테스트합니다.

### Step 3. 런타임 에러 정밀 복구 (`/debug-runtime`)
직접 Swagger나 프론트엔드에서 API를 호출하다가 500 에러나 DB 스키마 충돌이 발생하면 아래 명령어를 입력합니다.
```text
/debug-runtime
```
- 에이전트가 `./logs/server.log` 최근 50줄과 에러 응답 JSON의 `error.location`을 분석해 원인을 찾아 수정합니다.
- 엔티티 컬럼 타입 변경 등으로 인한 H2 테이블 충돌인 경우 `./scripts/server-ctl.sh reset-db`로 로컬 DB를 초기화하고 시딩 데이터를 다시 채워 넣습니다.

### Step 4. 대화창 리셋 및 세션 인계 (`/handoff`)
기능 2~3개를 구현해 대화가 길어지면 에이전트 응답 속도와 정확도를 유지하기 위해 세션을 리셋합니다.
```text
/handoff
```
- 에이전트가 현재까지 구현된 엔티티·API와 다음 할 일을 `docs/PLAN.md` 상단(`1. Current Session State`)에 10줄 이내로 압축 기록하여 커밋하고, **새 대화창(New Conversation)**에 복사해 붙여넣을 시작 프롬프트 한 줄을 출력해 줍니다.

---

## 5. 내장 스크립트 치트시트 (CLI Reference)

에이전트뿐만 아니라 개발자도 터미널에서 아래 4개의 스크립트로 모든 환경을 제어할 수 있습니다.

| 명령어 | 동작 설명 |
| :--- | :--- |
| `./scripts/verify-fast.sh` | • 금지 어노테이션(`@ManyToOne`, `@JoinColumn`, `@Data` 등), `*ServiceImpl`, Security 의존성 적발<br>• Gradle Daemon 기반 Java 컴파일 체크 (캐시 히트 시 1~2초, 코드 변경 시 수 초, 첫 실행은 10초 이상 걸릴 수 있음) |
| `./scripts/server-ctl.sh start` | • 8080 포트 점유 확인 후 백그라운드로 Spring Boot 기동 및 `/actuator/health` 폴링(최대 60초). 다른 포트는 `PORT=8081 ./scripts/server-ctl.sh start` |
| `./scripts/server-ctl.sh restart` | • 8080을 LISTEN 중인 **Java 프로세스만** 종료(`lsof`/`fuser`/`netstat+taskkill`, 종료 대상 PID·이름 출력)하고 H2 `.lock.db` 정리 후 재기동. Java가 아닌 프로세스가 점유 중이면 건드리지 않고 `PORT=` 변경을 안내 (같은 프로젝트에서 두 포트를 동시에 띄우는 용도는 아님: Gradle 빌드 락으로 대기함) |
| `./scripts/server-ctl.sh stop` | • 실행 중인 백그라운드 서버 종료 및 포트 반환 |
| `./scripts/server-ctl.sh status` | • 현재 8080 서버 실행 여부 및 PID 상태 확인 |
| `./scripts/server-ctl.sh logs` | • `./logs/server.log`의 최근 50줄 즉시 출력 |
| `./scripts/server-ctl.sh reset-db` | • 서버 중지 → `./data/hackathon-db*` 파일 삭제 → 서버 재기동 및 `DataInitializer` 초기 데이터 재시딩 |
| `./scripts/smoke-test.sh [경로]` | • 지정한 경로(기본값 `/api/v1/samples`)로 `GET` 요청을 보내 2xx 응답 확인 (실패 시 서버 로그 자동 출력) |
| `./scripts/smoke-test.sh METHOD 경로 'JSON'` | • `POST`/`PUT`/`PATCH`/`DELETE` 지원. 예: `./scripts/smoke-test.sh POST /api/v1/samples '{"title":"a","category":"b","ownerId":1}'` |
| `./scripts/checkpoint.sh "메시지"` | • 커밋 접두사(`feat:`, `fix:`, `seed:`, `chore:`) 자동 보정 후 Git 체크포인트 커밋 생성 |
| `./scripts/checkpoint.sh --rollback` | • **스마트 롤백(비대화형)**: 작업 중 미커밋 파일이 있으면 미추적 파일까지 `git stash -u`(`rollback-backup-<시각>`)로 백업한 뒤 `HEAD` 상태로 복구하고, 이미 커밋한 직후라면 백업 태그(`rollback-backup-<시각>`)를 남기고 `HEAD~1`로 복구. 복원: `git stash pop` 또는 `git reset --hard <백업 태그>` |

---

## 6. 공통 API 응답 규격 및 자가 치유 메커니즘

모든 컨트롤러는 `ApiResponse<T>` 레코드 래퍼를 반환하며, `@JsonInclude(JsonInclude.Include.NON_NULL)`이 적용되어 불필요한 `null` 필드를 노출하지 않습니다.

### ✅ 성공 응답 예시 (`200 OK`)
```json
{
  "success": true,
  "data": {
    "id": 1,
    "title": "AI 해커톤 자동 검증 하네스 구축",
    "category": "DEVTOOLS",
    "ownerId": 1,
    "createdAt": "2026-10-26T23:15:00"
  }
}
```

### ❌ 에러 응답 예시 (`400 Bad Request` / `404` / `405` / `415` / `500`)
클라이언트 오류(없는 경로 `404`, 지원하지 않는 메서드 `405`, 잘못된 Content-Type `415`, 깨진 JSON·타입 불일치·필수 파라미터 누락 `400`)는 `log.warn` 한 줄만 남기고 원래의 4xx 상태코드로 응답하며, 진짜 서버 오류만 `500`과 스택트레이스를 남깁니다. 앱 코드 위치를 특정할 수 없는 경우 `location` 필드는 응답에서 생략됩니다.

`GlobalExceptionHandler`가 스택트레이스 중 `com.hackathon.app` 패키지 내부에서 발생한 위치만 추출하여 `error.location`에 담아 반환하므로, 에이전트가 수백 줄의 로그를 뒤지지 않고도 문제의 파일과 줄 번호를 즉시 찾아 수정합니다.
```json
{
  "success": false,
  "error": {
    "message": "해당 ID의 항목을 찾을 수 없습니다: 999",
    "location": "SampleItemService.java:53 (lambda$findById$0) <- SampleItemService.java:52 (findById)"
  }
}
```

---

## 7. 생성되는 디렉토리 및 파일 구조 (총 25개 파일)

```text
.
├── GEMINI.md                          # 전역 에이전트 행동 지침 및 Easy-Spring 6대 절대 규칙
├── build.gradle                       # Spring Boot 3.3.4 + Java 21 + H2 + Springdoc OpenAPI
├── settings.gradle                    # 프로젝트 루트 설정 (hackathon-app)
├── .gitignore                         # build, .gradle, data/, logs/, .env 커밋 제외
├── .agents/
│   ├── rules/
│   │   └── core-rules.md              # 골든 샘플 복제, 네이밍 컨벤션, 서버 제어 통합 규칙
│   └── workflows/
│       ├── spec.md                    # /spec : 기획 및 태스크 분해 (docs/PLAN.md 생성)
│       ├── implement-api.md           # /implement-api : 구현 + 시딩 + 검증 + 자가 치유 + 커밋
│       ├── debug-runtime.md           # /debug-runtime : server.log 분석 및 런타임 에러 복구
│       └── handoff.md                 # /handoff : 새 대화창 전환용 세션 상태 스냅샷 기록
├── docs/
│   └── PLAN.md                        # [단일 진실 공급원] 세션 상태 + 엔티티/API 명세 + 태스크 보드
├── scripts/
│   ├── verify-fast.sh                 # 금지 어노테이션/Security 정적 검사 & Gradle Daemon 고속 컴파일
│   ├── server-ctl.sh                  # Cross-Platform(Win/Mac/Linux) Java 좀비 안전 정리 & 서버 제어 (PORT 변경 가능)
│   ├── smoke-test.sh                  # 로컬 API curl 스모크 호출(GET/POST/PUT/DELETE) 및 에러 로그 자동 출력
│   └── checkpoint.sh                  # 커밋 접두사 자동 보정 & 백업 후 롤백(--rollback)
└── src/main/
    ├── resources/
    │   └── application.yml            # H2 로컬 파일 DB + 한글 Swagger(/swagger) + 파일 로깅 (H2 콘솔은 localhost 전용)
    └── java/com/hackathon/app/
        ├── HackathonApplication.java  # Spring Boot 메인 애플리케이션
        ├── common/
        │   ├── ApiResponse.java       # NON_NULL 경량 JSON 응답 래퍼 (record)
        │   ├── GlobalExceptionHandler.java # 파일명:줄번호(location) 자동 역추적 예외 핸들러
        │   ├── DataInitializer.java   # 서버 기동 시 데모용 초기 데이터 자동 시딩
        │   ├── CorsConfig.java        # 프론트엔드 연동용 전역 CORS 허용 설정
        │   └── OpenApiConfig.java     # Swagger UI 문서 메타데이터 설정
        └── sample/                    # 에이전트가 복제할 표준 CRUD 골든 샘플 1세트
            ├── SampleItem.java        # 단순 ID 참조(ownerId) 기반 엔티티
            ├── SampleItemRepository.java # Spring Data JPA 리포지토리
            ├── SampleItemService.java # 비즈니스 로직(GET/POST/PUT/DELETE) + Java 21 record DTO
            └── SampleItemController.java # 한글 @Tag/@Operation + ApiResponse 표준 컨트롤러
```
