#!/usr/bin/env bash
set -euo pipefail

echo "🚀 [하네스_해커톤_v1.1] Spring Boot 3 (Java 21) + Antigravity 다이어트 하네스(25개 파일) 생성을 시작합니다..."

# 덮어쓰기 보호: 이미 하네스가 설치된 프로젝트에서 다시 실행하면 작성 중인 코드(src/main/java)와 docs/ 가 삭제된다.
# (하네스 설치 흔적: docs/PLAN.md, common/ 또는 sample/ 패키지) FORCE=1 일 때만 덮어쓴다.
if [ "${FORCE:-0}" != "1" ]; then
  if [ -f docs/PLAN.md ] || [ -d src/main/java/com/hackathon/app/common ] || [ -d src/main/java/com/hackathon/app/sample ]; then
    echo "⚠️ [중단] 이미 하네스가 설치된 프로젝트입니다. 계속하면 src/main/java, docs/, .agents/rules 의 작업물이 모두 삭제됩니다."
    echo "   정말 덮어쓰려면: FORCE=1 ./bootstrap-harness.sh   (curl 파이프 사용 시: curl -fsSL <URL> | FORCE=1 bash)"
    exit 1
  fi
else
  echo "⚠️ FORCE=1 지정됨: 기존 src/main/java, docs/, .agents/rules 를 삭제하고 덮어씁니다."
fi

rm -rf src/main/java/* src/test/java/* .agents/rules/* .agents/skills/* docs/*
rm -f src/main/resources/application.properties build.gradle.kts
mkdir -p .agents/rules .agents/workflows docs scripts logs data src/main/resources src/main/java/com/hackathon/app/common src/main/java/com/hackathon/app/sample

# gradlew가 없는 빈 디렉터리 대응: 시스템 gradle이 있으면 wrapper를 자동 생성
if [ ! -f ./gradlew ]; then
  if command -v gradle >/dev/null 2>&1; then
    echo "⚙️ ./gradlew가 없어 시스템 gradle로 wrapper(8.10.2)를 생성합니다..."
    [ -f settings.gradle ] || [ -f settings.gradle.kts ] || echo "rootProject.name = 'hackathon-app'" > settings.gradle
    gradle wrapper --gradle-version 8.10.2 -q || echo "⚠️ wrapper 자동 생성에 실패했습니다. IntelliJ로 Gradle 프로젝트를 먼저 생성하세요."
  else
    echo "⚠️ ./gradlew와 gradle 명령어가 모두 없습니다. IntelliJ로 Gradle 프로젝트를 먼저 생성하세요."
  fi
fi

cat << 'EOF_HARNESS_FILE' > "GEMINI.md"
# Solo Hackathon Harness — Spring Boot 3 (Java 21)

이 프로젝트는 1인 단기 해커톤 완주를 위해 설계된 **방어형 Spring Boot 3.x (Java 21) 백엔드 하네스**입니다.

## 1. 커뮤니케이션 & 자율 검증 원칙
- 사용자는 Spring 내부 메커니즘에 익숙하지 않다. 프레임워크 내부 용어 대신 **비즈니스 동작과 테스트 방법(Swagger URL 등)**만 간결하게 안내한다.
- 코드 작성 후 검증을 사용자에게 떠넘기지 않는다. 반드시 에이전트가 직접 `./scripts/verify-fast.sh` → `./scripts/server-ctl.sh restart` → `./scripts/smoke-test.sh`를 실행해 확인한 뒤 보고한다.

## 2. Easy-Spring 6대 절대 규칙 (위반 시 정적 검사기에서 차단됨)
1. **JPA 연관관계 전면 금지**: `@OneToMany`, `@ManyToOne`, `@OneToOne`, `@ManyToMany`, `@JoinColumn`, `@ElementCollection`을 절대 쓰지 않는다. 타 엔티티 참조는 무조건 단순 ID 필드(`private Long userId;`)로 선언한다.
2. **Spring Security 금지**: `spring-boot-starter-security`를 추가하지 않는다. 사용자 식별이 필요하면 요청 DTO의 ID 필드(예: `ownerId`) 또는 `X-Demo-User-Id` 헤더(기본값 `1`)로 처리한다.
3. **Java 21 `record` DTO 필수**: 모든 Request/Response DTO는 Lombok `@Data`/`@Builder` 대신 `Service` 클래스 내부 또는 도메인 패키지에 `public record`로 작성한다.
4. **골든 샘플 복제 & 평면 패키지**: 신규 도메인은 `com.hackathon.app.<도메인>` 아래에 평면 배치(`Entity`, `Repository`, `Service`, `Controller`)하며, `*ServiceImpl` 분리를 금지한다. 반드시 `sample/` 패키지의 골든 샘플 패턴을 복제한다.
5. **시딩 데이터 의무 추가**: 신규 Entity 추가 시 `common/DataInitializer.java`에 데모용 초기 데이터 3건 이상을 `if (repo.count() == 0)` 조건으로 함께 추가한다.
6. **단일 기획서(`docs/PLAN.md`) & 안전 체크포인트**: 모든 설계와 진행 상태는 `docs/PLAN.md` 한 곳에서 관리하며, 검증 통과 후 `./scripts/checkpoint.sh "<타입>: <한글 요약>"`으로 커밋한다.
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > ".agents/rules/core-rules.md"
---
description: Spring Boot 3 코드 구현, 네이밍, 서버 제어 및 Git 체크포인트 핵심 규칙
---

# Core Implementation & Runtime Rules

## 1. 골든 샘플(Golden Sample) 복제 및 코드 컨벤션
- 새 도메인 구현 전 `src/main/java/com/hackathon/app/sample/`의 4개 파일을 참고하여 동일한 어노테이션과 구조를 유지한다.
- **REST URI**: `/api/v1/<복수형-케밥-케이스>` (예: `/api/v1/study-groups`)
- **DB 테이블명**: `@Table(name = "<snake_case_복수형>")` (예: `study_groups`)
- **메서드 네이밍**: 기본 CRUD는 골든 샘플(`findItems`, `findById`, `create`, `update`, `delete`)을 따르되, 출석·매칭 등 도메인 특화 액션은 직관적인 비즈니스 메서드명(예: `joinGroup`, `checkIn`)을 자유롭게 사용한다.
- **예외 처리**: 비즈니스 오류는 `throw new IllegalArgumentException("한글 에러 메시지")`를 던지면 `GlobalExceptionHandler`가 400 응답과 에러 발생 위치(`파일:줄번호`)를 자동 반환한다.
- **한글 Swagger**: 모든 Controller에 `@Tag(name = "도메인명 API")`, 각 메서드에 `@Operation(summary = "한글 설명")`을 작성한다.

## 2. 고속 검증 및 서버 제어 규칙 (직접 bootRun 금지)
- 무거운 `./gradlew test`나 직접 `./gradlew bootRun` 실행을 금지한다 (포트 8080 좀비 프로세스 원인).
- **1단계 정적/컴파일 검증 (캐시 히트 시 1~2초, 코드 변경 시 수 초)**: `./scripts/verify-fast.sh`
- **2단계 서버 재기동**: `./scripts/server-ctl.sh restart` (상태: `status`, 로그: `logs`, DB초기화: `reset-db`)
- **3단계 런타임 스모크 테스트**: `./scripts/smoke-test.sh /api/v1/<엔드포인트>` (POST/PUT/DELETE: `./scripts/smoke-test.sh POST /api/v1/<엔드포인트> '<JSON>'`)
- **4단계 Git 체크포인트**: `./scripts/checkpoint.sh "<feat|fix|seed|chore>: <한글 요약>"` (복구 필요 시 `--rollback`)
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > ".agents/workflows/spec.md"
---
description: 해커톤 아이디어를 받아 통합 기획 및 태스크 보드(docs/PLAN.md)를 생성합니다. (코드 수정 없음)
---

# /spec — 해커톤 기획 및 태스크 분해 워크플로우

사용자가 서비스 아이디어나 요구사항을 입력하면 **코드를 바로 작성하지 말고** 아래 순서만 수행한다:

1. **핵심 도메인 압축**:
   - 해커톤 시간 내에 완주 가능한 **핵심 엔티티 2~4개**와 **핵심 API 5~8개**로 압축한다.
   - 모든 엔티티는 연관관계 어노테이션 없이 단순 ID 참조 필드(`Long xxxId`)로만 설계한다.
2. **`docs/PLAN.md` 작성**:
   - `docs/PLAN.md` 파일 하나에 ① 현재 세션 상태(`Current Session State`), ② 엔티티 설계 표(`snake_case` 복수형 테이블명), ③ 핵심 API 목록, ④ 15분 단위 구현 체크리스트(`- [ ] Task 1: ...`)를 통합 작성한다.
3. **기획 체크포인트 저장**:
   - `./scripts/checkpoint.sh "chore: 해커톤 서비스 기획 및 태스크 정의 (PLAN.md)"`를 실행한다.
   - 작성된 기획과 태스크 목록을 요약해 보여주고, `/implement-api`로 첫 번째 태스크를 시작할지 물어본다.
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > ".agents/workflows/implement-api.md"
---
description: docs/PLAN.md의 다음 미완료 태스크 1개를 구현하고 시딩, 검증, 서버 재기동, 자가 치유, Git 커밋까지 원스톱 수행합니다.
---

# /implement-api — 원스톱 기능 구현 & 자가 검증 루프

1. **태스크 확인**:
   - `docs/PLAN.md`를 읽고 첫 번째 미완료 항목(`[ ]`)을 확인한다.
2. **골든 샘플 복제 구현**:
   - `src/main/java/com/hackathon/app/sample/` 구조를 복제하여 `com.hackathon.app.<도메인>` 패키지에 `Entity`, `Repository`, `Service`(`record` DTO 포함), `Controller`(한글 Swagger 및 `ApiResponse` 적용)를 작성한다.
3. **데모 데이터 시딩 추가**:
   - 신규 엔티티가 있다면 `common/DataInitializer.java`에 데모 데이터 3건 이상을 `if (repo.count() == 0)` 조건으로 추가한다.
4. **고속 컴파일 검증**:
   - `./scripts/verify-fast.sh`를 실행한다. 규칙 위반이나 컴파일 에러가 나면 즉시 수정하여 통과시킨다.
5. **서버 재기동 & 스모크 테스트 (자가 치유 포함)**:
   - `./scripts/server-ctl.sh restart` 후 `./scripts/smoke-test.sh <신규_API_경로>`를 실행한다.
   - 생성·수정·삭제 동작도 `./scripts/smoke-test.sh POST|PUT|DELETE <경로> '<JSON_BODY>'`로 확인한다.
   - 만약 500 에러나 기동 실패가 발생하면 출력된 로그와 `error.location`을 보고 즉시 코드를 수정(스키마 충돌 시 `./scripts/server-ctl.sh reset-db`)한 뒤 재검증한다.
6. **체크포인트 저장 및 완료 보고**:
   - `docs/PLAN.md`에서 해당 태스크를 `[x]`로 바꾸고 `Current Session State`를 갱신한다.
   - `./scripts/checkpoint.sh "feat: <구현한_기능_한글_요약>"`으로 커밋한다.
   - 구현된 API 요약과 Swagger 주소(`http://localhost:8080/swagger`)를 안내한다.
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > ".agents/workflows/debug-runtime.md"
---
description: 서버 기동 실패나 API 런타임 에러 발생 시 logs/server.log를 분석해 원인을 찾고 즉시 복구합니다.
---

# /debug-runtime — 런타임 에러 정밀 복구 워크플로우

1. **로그 수집 및 위치 특정**:
   - `./scripts/server-ctl.sh logs`를 실행해 `./logs/server.log`의 최근 50줄과 에러 응답 JSON의 `error.location`(`파일명:줄번호`)을 확인한다.
2. **원인별 자가 복구**:
   - **코드/로직 에러**: 해당 파일과 줄 번호를 열어 즉시 수정한다.
   - **H2 DB 스키마/컬럼 충돌**: 엔티티 필드 변경으로 인한 에러라면 `./scripts/server-ctl.sh reset-db`로 DB를 초기화하고 `DataInitializer`로 재시딩한다.
   - **코드가 심각하게 꼬인 경우**: `./scripts/checkpoint.sh --rollback`으로 직전 정상 상태로 되돌린다.
3. **재검증 및 커밋**:
   - `./scripts/verify-fast.sh` → `./scripts/server-ctl.sh restart` → `./scripts/smoke-test.sh` 통과 후 `./scripts/checkpoint.sh "fix: <수정한_에러_요약>"`으로 커밋한다.
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > ".agents/workflows/handoff.md"
---
description: 대화가 길어져 에이전트가 느려지기 전에 현재 상태를 docs/PLAN.md에 기록하고 새 대화창 전환 프롬프트를 출력합니다.
---

# /handoff — 대화 세션 리셋 및 컨텍스트 핸드오프

1. **상태 스냅샷 최신화**:
   - `docs/PLAN.md` 상단의 `## 1. Current Session State` 섹션에 현재 완료된 엔티티, 활성 API 목록, 다음 우선순위 태스크를 10줄 이내로 압축 기록한다.
2. **안전 체크포인트 커밋**:
   - `./scripts/verify-fast.sh` 실행 후 `./scripts/checkpoint.sh "chore: 세션 핸드오프 상태 스냅샷 저장"`으로 커밋한다.
3. **새 대화창 시작 프롬프트 안내**:
   - 사용자에게 **새 대화(New Conversation)**를 열고 아래 문장을 붙여넣으라고 안내한다:
     > `docs/PLAN.md를 읽고 다음 미완료 태스크를 /implement-api 워크플로우로 이어서 구현해줘.`
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > ".gitignore"
.gradle/
build/
!gradle/wrapper/gradle-wrapper.jar
data/
logs/
.env
*.class
*.log
.DS_Store
.idea/
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > "build.gradle"
plugins {
    id 'java'
    id 'org.springframework.boot' version '3.3.4'
    id 'io.spring.dependency-management' version '1.1.6'
}

group = 'com.hackathon'
version = '0.0.1-SNAPSHOT'

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

configurations {
    compileOnly {
        extendsFrom annotationProcessor
    }
}

repositories {
    mavenCentral()
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.springframework.boot:spring-boot-starter-validation'
    implementation 'org.springframework.boot:spring-boot-starter-actuator'

    // Swagger UI (/swagger) & OpenAPI (/v3/api-docs)
    implementation 'org.springdoc:springdoc-openapi-starter-webmvc-ui:2.6.0'

    // H2 Database (로컬 파일 모드로 동작하여 재시작 시에도 데이터 유지)
    runtimeOnly 'com.h2database:h2'

    compileOnly 'org.projectlombok:lombok'
    annotationProcessor 'org.projectlombok:lombok'

    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testRuntimeOnly 'org.junit.platform:junit-platform-launcher'
}

tasks.named('test') {
    useJUnitPlatform()
}
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > "settings.gradle"
rootProject.name = 'hackathon-app'
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > "docs/PLAN.md"
# Hackathon Master Plan (Spec & Tasks)

> `/spec` 실행 시 이 파일에 기획 명세와 태스크가 통합 생성되며, `/implement-api` 및 `/handoff` 시 상태가 자동 갱신됩니다.

## 1. Current Session State
- **최근 완료 작업**: 하네스 v1.1 초기 세팅 및 골든 샘플(`SampleItem` 전체 CRUD + 시딩) 구축 완료
- **현재 활성 엔티티**: `SampleItem` (`sample_items`)
- **현재 활성 API**: `GET/POST /api/v1/samples`, `GET/PUT/DELETE /api/v1/samples/{id}`
- **다음 우선순위**: `/spec`으로 해커톤 아이디어 구체화 후 첫 번째 도메인 구현

## 2. 엔티티 설계 (연관관계 어노테이션 없이 단순 ID 참조)
| 엔티티명 | 테이블명 (`snake_case` 복수형) | 주요 필드 | 비고 (시딩 여부) |
| :--- | :--- | :--- | :--- |
| `SampleItem` | `sample_items` | `id (Long)`, `title (String)`, `category (String)`, `ownerId (Long)`, `createdAt (LocalDateTime)` | 골든 샘플 (`DataInitializer` 3건 시딩) |

## 3. 핵심 API 목록 (`/api/v1/복수형-케밥-케이스`)
| Method | Endpoint | 설명 | 요청 DTO (`record`) | 응답 데이터 |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/samples` | 샘플 목록 조회 (카테고리 필터 지원) | Query: `category` (선택) | `List<SampleResponse>` |
| `GET` | `/api/v1/samples/{id}` | 샘플 단건 상세 조회 | Path: `id` | `SampleResponse` |
| `POST` | `/api/v1/samples` | 신규 샘플 등록 | `CreateSampleRequest` | `SampleResponse` |
| `PUT` | `/api/v1/samples/{id}` | 샘플 수정 (더티 체킹) | `UpdateSampleRequest` | `SampleResponse` |
| `DELETE` | `/api/v1/samples/{id}` | 샘플 삭제 | Path: `id` | `Void` |

## 4. Implementation Checklist
- [x] Task 0: 기본 하네스 및 골든 샘플(`sample` 패키지) 동작 확인
- [ ] Task 1: (`/spec` 실행 시 15분 단위 태스크가 이곳에 생성됩니다)
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > "scripts/checkpoint.sh"
#!/usr/bin/env bash
# checkpoint.sh — 컨벤션 자동 보정 Git 체크포인트 저장 및 상태 감지형 원클릭 롤백 스크립트
# 사용법:
#   저장: ./scripts/checkpoint.sh "feat: 샘플 API 구현"
#   복구: ./scripts/checkpoint.sh --rollback   (비대화형. 복구 직전에 stash/태그로 자동 백업하므로 언제든 되살릴 수 있음)
set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git init -q
  git branch -M main 2>/dev/null || true
  git add -A
  git commit -q -m "chore: 해커톤 하네스 v1.1 초기 세팅"
fi

if [ "${1:-}" = "--rollback" ]; then
  TS=$(date +%s)
  if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    echo "⏪ [checkpoint] 미커밋 변경사항(미추적 파일 포함)을 백업한 뒤 마지막 정상 커밋(HEAD)으로 복구합니다..."
    if ! git stash push -u -m "rollback-backup-${TS}" >/dev/null; then
      echo "❌ [checkpoint] 백업(stash)에 실패해 데이터 보호를 위해 롤백을 중단합니다. (git config user.name / user.email 설정 확인)"
      exit 1
    fi
    echo "💾 [checkpoint] 백업 완료: 'rollback-backup-${TS}' (확인: git stash list / 복원: git stash pop)"
  elif git rev-parse --verify -q HEAD~1 >/dev/null; then
    git tag "rollback-backup-${TS}" HEAD
    echo "⏪ [checkpoint] 직전 커밋을 취소하고 이전 체크포인트(HEAD~1)로 되돌립니다..."
    git reset -q --hard HEAD~1
    echo "💾 [checkpoint] 백업 태그: rollback-backup-${TS} (복원: git reset --hard rollback-backup-${TS})"
  else
    echo "ℹ️ [checkpoint] 되돌릴 이전 체크포인트가 없습니다."
  fi
  echo "✅ [checkpoint] 복구 완료: $(git log -1 --oneline 2>/dev/null || echo '커밋 없음')"
  exit 0
fi

RAW_MSG="${1:-chore: 검증 완료 체크포인트 저장}"

if [[ ! "${RAW_MSG}" =~ ^(feat|fix|seed|chore|refactor|docs):[[:space:]] ]]; then
  MSG="feat: ${RAW_MSG}"
else
  MSG="${RAW_MSG}"
fi

git add -A
if git diff --cached --quiet; then
  echo "ℹ️ [checkpoint] 변경된 파일이 없어 커밋을 건너뜁니다."
else
  git commit -q -m "${MSG}"
  echo "✅ [checkpoint] 안전 복구 지점 저장 완료: $(git log -1 --oneline)"
fi
EOF_HARNESS_FILE
chmod +x "scripts/checkpoint.sh"

cat << 'EOF_HARNESS_FILE' > "scripts/server-ctl.sh"
#!/usr/bin/env bash
# server-ctl.sh — Cross-Platform(Windows Git Bash / Mac / Linux) 서버 제어기 (Java 프로세스만 안전하게 정리)
# 사용법: ./scripts/server-ctl.sh {start|stop|restart|status|logs|reset-db}
# 포트 변경: PORT=8081 ./scripts/server-ctl.sh restart   (기본값 8080)
set -euo pipefail

PORT="${PORT:-8080}"
LOG_DIR="./logs"
LOG_FILE="${LOG_DIR}/server.log"
PID_FILE="${LOG_DIR}/server.pid"
HEALTH_URL="http://localhost:${PORT}/actuator/health"
CLEANED=0   # restart 시 stop_server 결과 경고가 start_server에서 중복 출력되지 않도록 표시

mkdir -p "${LOG_DIR}" ./data

# 해당 포트를 LISTEN 중인 프로세스 PID 목록 (브라우저 등 단순 접속 중인 클라이언트는 제외)
find_port_pids() {
  if command -v lsof >/dev/null 2>&1; then
    lsof -ti:"${PORT}" -sTCP:LISTEN 2>/dev/null || true
  elif command -v fuser >/dev/null 2>&1; then
    fuser "${PORT}/tcp" 2>/dev/null || true
  elif command -v netstat >/dev/null 2>&1; then
    netstat -ano 2>/dev/null | grep ":${PORT} " | grep "LISTENING" | awk '{print $5}' | tr -d '\r' | sort -u || true
  fi
}

# PID의 프로세스 이름 (Windows: tasklist, Mac/Linux: ps)
proc_name() {
  local pid=$1 name=""
  if command -v tasklist >/dev/null 2>&1; then
    name=$(tasklist //FI "PID eq ${pid}" //FO CSV //NH 2>/dev/null | head -n 1 | cut -d, -f1 | tr -d '"\r' || true)
    case "${name}" in INFO*) name="" ;; esac
  fi
  if [ -z "${name}" ]; then
    name=$(ps -p "${pid}" -o comm= 2>/dev/null || true)
  fi
  echo "${name}"
}

is_java() {
  case "$(echo "${1:-}" | tr '[:upper:]' '[:lower:]')" in
    *java*) return 0 ;;
    *) return 1 ;;
  esac
}

kill_pid_force() {
  local target_pid=$1
  if [ -z "${target_pid}" ] || [ "${target_pid}" = "0" ]; then
    return 0
  fi
  if command -v taskkill >/dev/null 2>&1; then
    taskkill //F //T //PID "${target_pid}" >/dev/null 2>&1 || true
  else
    kill -9 "${target_pid}" 2>/dev/null || true
  fi
}

stop_server() {
  CLEANED=1
  echo "🛑 [server-ctl] ${PORT}번 포트 점유 프로세스 확인 및 정리 중..."
  if [ -f "${PID_FILE}" ]; then
    SAVED_PID=$(cat "${PID_FILE}" || true)
    if [ -n "${SAVED_PID}" ]; then
      # PID 재사용으로 무관한 프로세스를 죽이지 않도록 gradlew 계열(java/쉘/cmd)일 때만 종료
      SAVED_NAME=$(proc_name "${SAVED_PID}" | tr '[:upper:]' '[:lower:]')
      case "${SAVED_NAME}" in
        *java*|*sh|*gradle*|*cmd*) kill_pid_force "${SAVED_PID}" ;;
      esac
    fi
    rm -f "${PID_FILE}"
  fi

  PIDS=$(find_port_pids)
  SKIPPED=0
  for pid in ${PIDS}; do
    name=$(proc_name "${pid}")
    if is_java "${name}"; then
      echo "   -> Java 프로세스 종료 (PID: ${pid}, 이름: ${name})"
      kill_pid_force "${pid}"
    else
      echo "   ⚠️ 건너뜀 (PID: ${pid}, 이름: ${name:-알 수 없음}) — Java 프로세스가 아니라서 종료하지 않습니다."
      SKIPPED=1
    fi
  done
  if [ -n "${PIDS}" ]; then
    sleep 1
  fi
  rm -f ./data/*.lock.db 2>/dev/null || true

  if [ "${SKIPPED}" = "1" ]; then
    echo "⚠️ [server-ctl] 포트 ${PORT}를 다른 프로그램이 사용 중입니다. 다른 포트로 실행하세요: PORT=8081 ./scripts/server-ctl.sh restart"
  else
    echo "✅ [server-ctl] 포트 ${PORT} 정리 완료."
  fi
}

start_server() {
  PIDS=$(find_port_pids)
  if [ -n "${PIDS}" ]; then
    if [ "${CLEANED}" != "1" ]; then
      echo "⚠️ [server-ctl] 이미 ${PORT}번 포트가 사용 중입니다 (PID: ${PIDS}). 정리를 먼저 수행합니다."
      stop_server
    fi
    if [ -n "$(find_port_pids)" ]; then
      echo "❌ [server-ctl] 포트 ${PORT}가 여전히 점유되어 있어 서버를 기동하지 않습니다. (PORT=8081 ./scripts/server-ctl.sh start)"
      return 1
    fi
  fi

  echo "🚀 [server-ctl] Spring Boot 서버 백그라운드 기동 중... (포트 ${PORT})"
  : > "${LOG_FILE}"
  SERVER_PORT="${PORT}" nohup ./gradlew bootRun --daemon -q > "${LOG_FILE}" 2>&1 &
  NEW_PID=$!
  echo "${NEW_PID}" > "${PID_FILE}"

  echo "⏳ [server-ctl] 서버 Health 체크 대기 중 (${HEALTH_URL})..."
  MAX_WAIT=60
  for ((i=1; i<=MAX_WAIT; i++)); do
    if curl -fsS "${HEALTH_URL}" 2>/dev/null | grep -q '"status":"UP"'; then
      echo "✅ [server-ctl] 서버 기동 완료! (${i}초 소요)"
      echo "   👉 Swagger UI: http://localhost:${PORT}/swagger"
      echo "   👉 H2 DB 콘솔: http://localhost:${PORT}/h2-console (JDBC URL: jdbc:h2:file:./data/hackathon-db)"
      return 0
    fi
    sleep 1
  done

  echo "❌ [server-ctl] ${MAX_WAIT}초 내에 서버가 기동되지 않았습니다. 최근 에러 로그:"
  tail -n 40 "${LOG_FILE}" || true
  return 1
}

status_server() {
  PIDS=$(find_port_pids)
  if [ -n "${PIDS}" ] && curl -fsS "${HEALTH_URL}" 2>/dev/null | grep -q '"status":"UP"'; then
    echo "🟢 [server-ctl] 서버 정상 실행 중 (PID: ${PIDS}, Port: ${PORT})"
    return 0
  else
    echo "⚪ [server-ctl] 서버가 실행 중이지 않습니다."
    return 1
  fi
}

case "${1:-status}" in
  start)
    start_server
    ;;
  stop)
    stop_server
    ;;
  restart)
    stop_server
    start_server
    ;;
  status)
    status_server
    ;;
  logs)
    tail -n 50 "${LOG_FILE}" 2>/dev/null || echo "아직 생성된 로그 파일이 없습니다."
    ;;
  reset-db)
    stop_server
    rm -rf ./data/hackathon-db*
    echo "🗑️ [server-ctl] 로컬 H2 DB 파일을 초기화했습니다. 재기동 시 DataInitializer가 시딩 데이터를 다시 채웁니다."
    start_server
    ;;
  *)
    echo "사용법: $0 {start|stop|restart|status|logs|reset-db}   (포트 변경: PORT=8081 $0 restart)"
    exit 1
    ;;
esac
EOF_HARNESS_FILE
chmod +x "scripts/server-ctl.sh"

cat << 'EOF_HARNESS_FILE' > "scripts/smoke-test.sh"
#!/usr/bin/env bash
# smoke-test.sh — 로컬 API 런타임 스모크 검증기
# 사용법:
#   ./scripts/smoke-test.sh [/api/v1/samples]                  # 경로만 주면 GET (기본값 /api/v1/samples)
#   ./scripts/smoke-test.sh [METHOD] [경로] [JSON_BODY]         # 예: POST /api/v1/samples '{"title":"a","category":"b","ownerId":1}'
# 포트 변경: PORT=8081 ./scripts/smoke-test.sh ...
set -euo pipefail

export PORT="${PORT:-8080}"
BASE_URL="http://localhost:${PORT}"

FIRST_UPPER=$(printf '%s' "${1:-}" | tr '[:lower:]' '[:upper:]')
case "${FIRST_UPPER}" in
  GET|POST|PUT|PATCH|DELETE)
    METHOD="${FIRST_UPPER}"
    TARGET_PATH="${2:-/api/v1/samples}"
    BODY="${3:-}"
    ;;
  *)
    METHOD="GET"
    TARGET_PATH="${1:-/api/v1/samples}"
    BODY=""
    ;;
esac

echo "🌐 [1/2] 서버 상태 확인 중..."
if ! curl -fsS "${BASE_URL}/actuator/health" >/dev/null 2>&1; then
  echo "⚠️ 서버가 꺼져 있어 자동으로 기동합니다..."
  ./scripts/server-ctl.sh start
fi

echo "🌐 [2/2] ${METHOD} ${BASE_URL}${TARGET_PATH} 호출 중..."
CURL_ARGS=(-s -w "\nHTTP_STATUS:%{http_code}" -X "${METHOD}")
if [ -n "${BODY}" ]; then
  CURL_ARGS+=(-H "Content-Type: application/json" -d "${BODY}")
fi
HTTP_RESPONSE=$(curl "${CURL_ARGS[@]}" "${BASE_URL}${TARGET_PATH}" || true)
HTTP_BODY=$(echo "${HTTP_RESPONSE}" | sed -e 's/HTTP_STATUS\:.*//g')
HTTP_STATUS=$(echo "${HTTP_RESPONSE}" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')
if ! [[ "${HTTP_STATUS}" =~ ^[0-9]+$ ]]; then
  HTTP_STATUS=000
fi

echo "   -> 응답 상태코드: ${HTTP_STATUS}"
echo "   -> 응답 본문 요약: $(echo "${HTTP_BODY}" | head -c 300)"

if [ "${HTTP_STATUS}" -ge 200 ] && [ "${HTTP_STATUS}" -lt 300 ]; then
  echo "✅ [smoke-test] API 정상 응답 확인 완료!"
else
  echo "❌ [smoke-test] API 에러 발생! 최근 서버 로그(logs/server.log):"
  tail -n 35 ./logs/server.log || true
  exit 1
fi
EOF_HARNESS_FILE
chmod +x "scripts/smoke-test.sh"

cat << 'EOF_HARNESS_FILE' > "scripts/verify-fast.sh"
#!/usr/bin/env bash
# verify-fast.sh — 1단계 정적 규칙 & 컴파일 검증기 (캐시 히트 시 1~2초, 코드 변경 시 수 초)
set -euo pipefail

echo "🔍 [1/3] 금지된 JPA 연관관계 및 Security 의존성 정적 검사 중..."
if grep -rnE "^[[:space:]]*@(OneToMany|ManyToOne|OneToOne|ManyToMany|JoinColumn|ElementCollection)" src/main/java/ 2>/dev/null; then
  echo "❌ [규칙 위반] JPA 연관관계/조인 어노테이션이 감지되었습니다! 단순 ID 필드(Long xxxId)로 변경하세요."
  exit 1
fi

if grep -q "spring-boot-starter-security" build.gradle 2>/dev/null; then
  echo "❌ [규칙 위반] build.gradle에 Spring Security가 추가되었습니다! 즉시 제거하세요."
  exit 1
fi

echo "🔍 [2/3] 아키텍처 컨벤션(*ServiceImpl 분리, @Data/@Builder 사용) 검사 중..."
if find src/main/java/ -name "*ServiceImpl.java" | grep -q .; then
  echo "❌ [규칙 위반] 불필요한 *ServiceImpl 클래스가 감지되었습니다! 단일 @Service 클래스로 작성하세요."
  exit 1
fi

if grep -rnE "^[[:space:]]*@(Data|Builder)" src/main/java/ 2>/dev/null; then
  echo "❌ [규칙 위반] @Data 또는 @Builder가 감지되었습니다! Entity는 @Getter/@Setter, DTO는 Java 21 record를 사용하세요."
  exit 1
fi

echo "🔍 [3/3] Gradle Daemon 고속 컴파일 검증 중..."
if ! OUTPUT=$(./gradlew compileJava --daemon --console=plain 2>&1); then
  echo "❌ [컴파일 실패] 핵심 에러 내역:"
  echo "${OUTPUT}" | grep -E "(error:|warning:|FAILED|Exception)" -A 3 | head -n 35
  exit 1
fi

echo "✅ [verify-fast] 코드 컨벤션 및 컴파일 검증 통과!"
EOF_HARNESS_FILE
chmod +x "scripts/verify-fast.sh"

cat << 'EOF_HARNESS_FILE' > "src/main/java/com/hackathon/app/HackathonApplication.java"
package com.hackathon.app;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class HackathonApplication {
    public static void main(String[] args) {
        SpringApplication.run(HackathonApplication.class, args);
    }
}
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > "src/main/java/com/hackathon/app/common/ApiResponse.java"
package com.hackathon.app.common;

import com.fasterxml.jackson.annotation.JsonInclude;

/**
 * 불필요한 메타데이터를 걷어내고 성공 데이터와 에러 위치(location)만 깔끔하게 전달하는 경량 레코드 래퍼.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiResponse<T>(
        boolean success,
        T data,
        ErrorDetail error
) {
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record ErrorDetail(
            String message,
            String location
    ) {}

    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, data, null);
    }

    public static <T> ApiResponse<T> fail(String message, String location) {
        return new ApiResponse<>(false, null, new ErrorDetail(message, location));
    }
}
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > "src/main/java/com/hackathon/app/common/CorsConfig.java"
package com.hackathon.app.common;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class CorsConfig implements WebMvcConfigurer {
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOriginPatterns("*")
                .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(false);
    }
}
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > "src/main/java/com/hackathon/app/common/DataInitializer.java"
package com.hackathon.app.common;

import com.hackathon.app.sample.SampleItem;
import com.hackathon.app.sample.SampleItemRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * [하네스 핵심 컴포넌트]
 * 서버 기동 시 DB가 비어 있으면 심사위원 데모용 초기 데이터를 자동으로 채워 넣습니다.
 * 새로운 도메인(Entity/Repository)을 추가할 때마다 아래 run() 메서드에 시딩 로직을 추가하세요.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class DataInitializer implements ApplicationRunner {

    private final SampleItemRepository sampleItemRepository;

    @Override
    public void run(ApplicationArguments args) {
        seedSampleItems();
    }

    private void seedSampleItems() {
        long count = sampleItemRepository.count();
        if (count > 0) {
            log.info("[DataInitializer] SampleItem 데이터가 이미 존재하여 시딩을 건너뜁니다. (현재 {}건)", count);
            return;
        }

        List<SampleItem> demoItems = List.of(
                new SampleItem("AI 해커톤 자동 검증 하네스 구축", "DEVTOOLS", 1L),
                new SampleItem("실시간 사용자 피드백 요약 파이프라인", "AI_SERVICE", 1L),
                new SampleItem("모바일 웹뷰 기반 원클릭 데모 대시보드", "FRONTEND", 2L)
        );
        sampleItemRepository.saveAll(demoItems);
        log.info("[DataInitializer] 데모용 초기 SampleItem {}건 시딩 완료!", demoItems.size());
    }
}
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > "src/main/java/com/hackathon/app/common/GlobalExceptionHandler.java"
package com.hackathon.app.common;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.ErrorResponse;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.util.Arrays;
import java.util.stream.Collectors;

/**
 * 에이전트가 에러 원인과 코드 위치(파일명:줄번호)를 응답 JSON에서 즉시 읽고 자가 수정할 수 있게 돕는 전역 예외 핸들러.
 * - 클라이언트 잘못(4xx)은 log.warn 한 줄만 남기고 원래의 4xx 상태코드로 응답한다.
 * - 진짜 서버 오류(5xx)만 스택트레이스를 남긴다.
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiResponse<Void>> handleBadRequest(IllegalArgumentException ex) {
        log.warn("[BadRequest] {}", ex.getMessage());
        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.fail(ex.getMessage(), extractAppLocation(ex)));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleValidation(MethodArgumentNotValidException ex) {
        String message = ex.getBindingResult().getFieldErrors().stream()
                .map(err -> err.getField() + ": " + err.getDefaultMessage())
                .collect(Collectors.joining(", "));
        log.warn("[Validation] {}", message);
        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.fail(message, extractAppLocation(ex)));
    }

    @ExceptionHandler({
            HttpMessageNotReadableException.class,
            MethodArgumentTypeMismatchException.class,
            MissingServletRequestParameterException.class
    })
    public ResponseEntity<ApiResponse<Void>> handleBadInput(Exception ex) {
        String message;
        if (ex instanceof MethodArgumentTypeMismatchException mismatch) {
            message = "'" + mismatch.getName() + "' 값의 형식이 올바르지 않습니다: " + mismatch.getValue();
        } else if (ex instanceof MissingServletRequestParameterException missing) {
            message = "필수 파라미터가 없습니다: " + missing.getParameterName();
        } else if (String.valueOf(ex.getMessage()).startsWith("Required request body is missing")) {
            message = "요청 본문(JSON)이 비어 있습니다.";
        } else {
            message = "요청 본문(JSON)을 읽을 수 없습니다: " + shorten(rootMessage(ex));
        }
        log.warn("[BadInput] {}", message);
        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.fail(message, extractAppLocation(ex)));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleUnexpected(Exception ex) {
        // 404/405/415 등 스프링이 이미 상태코드를 정해 둔 예외는 500으로 덮어쓰지 않고 그대로 존중한다.
        if (ex instanceof ErrorResponse errorResponse && errorResponse.getStatusCode().is4xxClientError()) {
            log.warn("[{}] {}", errorResponse.getStatusCode().value(), ex.getMessage());
            return ResponseEntity
                    .status(errorResponse.getStatusCode())
                    .body(ApiResponse.fail(ex.getMessage(), extractAppLocation(ex)));
        }
        log.error("[UnhandledException] ", ex);
        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.fail(ex.getMessage(), extractAppLocation(ex)));
    }

    /** 앱 코드(com.hackathon.app) 프레임이 없으면 null → @JsonInclude(NON_NULL)로 location 필드가 응답에서 생략된다. */
    private String extractAppLocation(Throwable ex) {
        String location = Arrays.stream(ex.getStackTrace())
                .filter(frame -> frame.getClassName().startsWith("com.hackathon.app"))
                .limit(2)
                .map(frame -> frame.getFileName() + ":" + frame.getLineNumber() + " (" + frame.getMethodName() + ")")
                .collect(Collectors.joining(" <- "));
        return location.isEmpty() ? null : location;
    }

    private String rootMessage(Throwable ex) {
        Throwable root = ex;
        while (root.getCause() != null && root.getCause() != root) {
            root = root.getCause();
        }
        return String.valueOf(root.getMessage());
    }

    private String shorten(String text) {
        String firstLine = text.lines().findFirst().orElse("");
        return firstLine.length() > 200 ? firstLine.substring(0, 200) + "..." : firstLine;
    }
}
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > "src/main/java/com/hackathon/app/common/OpenApiConfig.java"
package com.hackathon.app.common;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {
    @Bean
    public OpenAPI hackathonOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("Hackathon API Server")
                        .version("v1.1")
                        .description("프론트엔드 없이 브라우저에서 즉시 시연 가능한 해커톤 API 문서 (/swagger)"));
    }
}
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > "src/main/java/com/hackathon/app/sample/SampleItem.java"
package com.hackathon.app.sample;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * [골든 샘플 Entity]
 * - JPA 연관관계(ManyToOne 등)를 절대 사용하지 않고 ownerId처럼 단순 Long 값으로 참조합니다.
 */
@Entity
@Table(name = "sample_items")
@Getter
@Setter
@NoArgsConstructor
public class SampleItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 120)
    private String title;

    @Column(nullable = false, length = 50)
    private String category;

    @Column(nullable = false)
    private Long ownerId;

    @Column(nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public SampleItem(String title, String category, Long ownerId) {
        this.title = title;
        this.category = category;
        this.ownerId = ownerId;
        this.createdAt = LocalDateTime.now();
    }
}
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > "src/main/java/com/hackathon/app/sample/SampleItemRepository.java"
package com.hackathon.app.sample;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SampleItemRepository extends JpaRepository<SampleItem, Long> {
    List<SampleItem> findByCategoryOrderByIdDesc(String category);
    List<SampleItem> findAllByOrderByIdDesc();
}
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > "src/main/java/com/hackathon/app/sample/SampleItemService.java"
package com.hackathon.app.sample;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * [골든 샘플 Service & Java 21 Record DTO]
 * - 불필요한 ServiceImpl 분리 없이 단일 클래스에서 트랜잭션과 Record DTO를 관리합니다.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SampleItemService {

    private final SampleItemRepository sampleItemRepository;

    public record CreateSampleRequest(
            @NotBlank(message = "제목은 필수입니다.") String title,
            @NotBlank(message = "카테고리는 필수입니다.") String category,
            @NotNull(message = "작성자 ID는 필수입니다.") Long ownerId
    ) {}

    public record UpdateSampleRequest(
            @NotBlank(message = "제목은 필수입니다.") String title,
            @NotBlank(message = "카테고리는 필수입니다.") String category
    ) {}

    public record SampleResponse(
            Long id,
            String title,
            String category,
            Long ownerId,
            LocalDateTime createdAt
    ) {
        public static SampleResponse from(SampleItem entity) {
            return new SampleResponse(
                    entity.getId(),
                    entity.getTitle(),
                    entity.getCategory(),
                    entity.getOwnerId(),
                    entity.getCreatedAt()
            );
        }
    }

    public List<SampleResponse> findItems(String category) {
        List<SampleItem> items = (category == null || category.isBlank())
                ? sampleItemRepository.findAllByOrderByIdDesc()
                : sampleItemRepository.findByCategoryOrderByIdDesc(category);
        return items.stream().map(SampleResponse::from).toList();
    }

    public SampleResponse findById(Long id) {
        SampleItem item = sampleItemRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("해당 ID의 항목을 찾을 수 없습니다: " + id));
        return SampleResponse.from(item);
    }

    @Transactional
    public SampleResponse create(CreateSampleRequest request) {
        SampleItem saved = sampleItemRepository.save(
                new SampleItem(request.title(), request.category(), request.ownerId())
        );
        return SampleResponse.from(saved);
    }

    @Transactional
    public SampleResponse update(Long id, UpdateSampleRequest request) {
        SampleItem item = sampleItemRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("수정할 항목을 찾을 수 없습니다: " + id));
        item.setTitle(request.title());
        item.setCategory(request.category());
        return SampleResponse.from(item);
    }

    @Transactional
    public void delete(Long id) {
        if (!sampleItemRepository.existsById(id)) {
            throw new IllegalArgumentException("삭제할 항목이 존재하지 않습니다: " + id);
        }
        sampleItemRepository.deleteById(id);
    }
}
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > "src/main/java/com/hackathon/app/sample/SampleItemController.java"
package com.hackathon.app.sample;

import com.hackathon.app.common.ApiResponse;
import com.hackathon.app.sample.SampleItemService.CreateSampleRequest;
import com.hackathon.app.sample.SampleItemService.SampleResponse;
import com.hackathon.app.sample.SampleItemService.UpdateSampleRequest;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * [골든 샘플 Controller]
 * - 모든 신규 도메인 컨트롤러는 이 클래스의 어노테이션과 ApiResponse 반환 패턴을 그대로 복제합니다.
 */
@Tag(name = "Sample API (골든 샘플)", description = "에이전트가 신규 기능 구현 시 복제할 표준 CRUD 템플릿")
@RestController
@RequestMapping("/api/v1/samples")
@RequiredArgsConstructor
public class SampleItemController {

    private final SampleItemService sampleItemService;

    @Operation(summary = "샘플 목록 조회", description = "카테고리 파라미터가 없으면 전체 목록을 최신순으로 반환합니다.")
    @GetMapping
    public ApiResponse<List<SampleResponse>> getSamples(
            @RequestParam(required = false) String category
    ) {
        return ApiResponse.ok(sampleItemService.findItems(category));
    }

    @Operation(summary = "샘플 단건 상세 조회")
    @GetMapping("/{id}")
    public ApiResponse<SampleResponse> getSample(@PathVariable Long id) {
        return ApiResponse.ok(sampleItemService.findById(id));
    }

    @Operation(summary = "신규 샘플 등록")
    @PostMapping
    public ApiResponse<SampleResponse> createSample(@Valid @RequestBody CreateSampleRequest request) {
        return ApiResponse.ok(sampleItemService.create(request));
    }

    @Operation(summary = "샘플 수정")
    @PutMapping("/{id}")
    public ApiResponse<SampleResponse> updateSample(
            @PathVariable Long id,
            @Valid @RequestBody UpdateSampleRequest request
    ) {
        return ApiResponse.ok(sampleItemService.update(id, request));
    }

    @Operation(summary = "샘플 삭제")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> deleteSample(@PathVariable Long id) {
        sampleItemService.delete(id);
        return ApiResponse.ok(null);
    }
}
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > "src/main/resources/application.yml"
server:
  port: 8080

spring:
  application:
    name: hackathon-app
  datasource:
    # 비정상 종료 시 락 충돌을 방지하면서 재시작 시에도 데이터가 유지되는 로컬 파일 모드
    url: jdbc:h2:file:./data/hackathon-db;MODE=MySQL;DB_CLOSE_ON_EXIT=FALSE
    driver-class-name: org.h2.Driver
    username: sa
    password:
  h2:
    console:
      enabled: true
      path: /h2-console
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
    properties:
      hibernate:
        format_sql: false

management:
  endpoints:
    web:
      exposure:
        include: health,info

springdoc:
  swagger-ui:
    path: /swagger
    operations-sorter: method
    tags-sorter: alpha
  api-docs:
    path: /v3/api-docs

logging:
  file:
    name: ./logs/server.log
  level:
    root: INFO
    com.hackathon.app: DEBUG
EOF_HARNESS_FILE

echo "✅ [하네스_해커톤_v1.1] 전체 25개 파일(린 매스업 버전) 생성이 완료되었습니다!"
echo "👉 다음 단계: ./scripts/verify-fast.sh && ./scripts/server-ctl.sh start"
