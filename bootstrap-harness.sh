#!/usr/bin/env bash
set -euo pipefail
echo "🚀 [하네스_해커톤_v1] Spring Boot 3 (Java 21) + Antigravity 전체 하네스(29개 파일) 생성을 시작합니다..."
rm -rf src/main/java/* src/test/java/*
rm -f src/main/resources/application.properties build.gradle.kts
mkdir -p .agents/rules .agents/workflows .agents/skills/api-smoke-test docs scripts logs data src/main/resources src/main/java/com/hackathon/app/common src/main/java/com/hackathon/app/sample

cat << 'EOF_HARNESS_FILE' > ".agents/rules/conventions-and-git.md"
---
description: 해커톤 저장소와 API 문서를 깔끔하게 정돈하기 위한 경량 코드 컨벤션 및 Git 커밋 규칙
---

# Lightweight Code & Git Conventions

과도한 제약 없이 코드 일관성과 Git 히스토리 가독성만 챙기는 해커톤용 경량 규칙입니다.

## 1. 코드 & API 네이밍 컨벤션
- **패키지 구조**: `com.hackathon.app.<도메인명>` 단위로 평면 배치한다. (도메인 폴더 안에 또 `controller`, `service` 하위 폴더를 나누지 않고 한 폴더에 `Entity`, `Repository`, `Service`, `Controller` 4개 파일을 모아둔다.)
- **REST API 주소**: `/api/v1/<복수형-케밥-케이스>`로 통일한다. (예: `/api/v1/study-groups`, `/api/v1/review-notes`)
- **DB 테이블명**: `@Table(name = "<snake_case_복수형>")`으로 명시한다. (예: `study_groups`, `sample_items`)
- **서비스 메서드명**: 조회는 `findItems` / `findById`, 생성은 `create`, 수정은 `update`, 삭제는 `delete`로 통일한다.
- **Swagger 한글 문서화**: 심사위원과 사용자가 `/swagger` 화면에서 한눈에 알아볼 수 있도록 모든 Controller에 `@Tag(name = "02. 도메인명 API")`, 각 메서드에 `@Operation(summary = "직관적인 한글 설명")`을 붙인다.

## 2. Git 브랜치 & 커밋 컨벤션
- **단일 브랜치(`main`) 운영**: 1인 해커톤에서 불필요한 브랜치 병합 충돌을 막기 위해 별도 브랜치를 파지 않고 `main` 브랜치에서 기능 단위로 체크포인트 커밋을 남긴다.
- **커밋 메시지 포맷**: `<타입>: <한글 요약>` 형식을 사용한다.
  - `feat: <요약>` — 새로운 도메인·API 기능 구현 (예: `feat: 스터디 모임 생성 및 목록 조회 API 구현`)
  - `fix: <요약>` — 런타임 에러나 버그 수정 (예: `fix: 모임 상세 조회 시 예외 메시지 누락 수정`)
  - `seed: <요약>` — `DataInitializer` 데모 시딩 데이터 추가·수정
  - `chore: <요약>` — 설정 변경, 기획서(`SPEC.md`/`TASKS.md`) 업데이트, 세션 핸드오프 스냅샷
- **안전 커밋 원칙**:
  - 반드시 `./scripts/verify-fast.sh`가 통과한 상태에서 `./scripts/checkpoint.sh "<타입>: <한글 요약>"`으로 커밋한다.
  - `.env`, `./logs/`, `./data/` 폴더는 절대 Git에 커밋하지 않는다.
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > ".agents/rules/easy-spring.md"
---
description: Spring Boot 3 (Java 21) 코드 작성 시 항상 적용되는 아키텍처 및 어노테이션 규칙
---

# Easy-Spring Implementation Rules

## 1. 골든 샘플(Golden Sample) 복제 원칙
- 새 기능(도메인)을 추가할 때는 `src/main/java/com/hackathon/app/sample/` 하위의 4개 파일(`SampleItem.java`, `SampleItemRepository.java`, `SampleItemService.java`, `SampleItemController.java`)을 먼저 읽고 동일한 스타일로 작성한다.
- 모든 컨트롤러 응답은 `ApiResponse.ok(data)`로 감싸서 반환한다.
- 예외를 던질 때는 `new IllegalArgumentException("직관적인 한글 에러 메시지")`를 사용하면 `GlobalExceptionHandler`가 자동으로 400 응답과 발생 위치(파일:줄번호)를 JSON으로 반환한다.

## 2. 데이터베이스 및 시딩 규칙
- DB는 설치가 필요 없으면서 서버 재시작 시에도 데이터가 유지되는 **H2 로컬 파일 모드(`jdbc:h2:file:./data/hackathon-db`)**를 사용한다.
- 엔티티 클래스에는 `@Entity`, `@Getter`, `@Setter`, `@NoArgsConstructor`만 사용하고 연관관계 매핑은 금지한다.
- 엔티티가 추가되거나 변경되면 `src/main/java/com/hackathon/app/common/DataInitializer.java`의 `run()` 내부에 `if (repository.count() == 0)` 조건으로 데모용 초기 데이터를 반드시 추가한다.
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > ".agents/rules/testing-and-runtime.md"
---
description: 빌드 지연과 포트 충돌을 막기 위한 검증 및 서버 실행 규칙
---

# Fast Verification & Server Control Rules

1. **전체 테스트 실행 지양**:
   - 코드 수정 직후에는 무거운 `./gradlew test` 대신 반드시 `./scripts/verify-fast.sh`를 실행해 2초 내에 컴파일 에러 여부를 먼저 확인한다.
2. **직접 `./gradlew bootRun` 실행 금지**:
   - 터미널에서 직접 `bootRun`을 실행하면 백그라운드 좀비 프로세스가 남아 8080 포트 충돌(`Port 8080 was already in use`)이 발생한다.
   - 서버 시작/재시작/중지는 무조건 `./scripts/server-ctl.sh start|restart|stop|status` 스크립트만 사용한다.
3. **런타임 에러 확인**:
   - API 호출 결과가 500이거나 서버가 기동되지 않으면 추측하지 말고 `./logs/server.log` 파일의 마지막 50줄을 읽어 정확한 원인을 파악한다.
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > ".agents/skills/api-smoke-test/SKILL.md"
---
name: api-smoke-test
description: 로컬 Spring Boot 서버의 상태 확인, OpenAPI 스키마 조회, 엔드포인트 curl 호출 및 에러 로그 진단을 수행하는 스킬
---

# API Smoke Test Skill

## 사용 시점
- 새로운 Controller 엔드포인트를 작성하거나 수정한 직후 실제 런타임 동작을 검증할 때 사용한다.

## 실행 절차
1. **서버 실행 상태 보장**:
   - `./scripts/server-ctl.sh status`로 8080 서버가 떠 있는지 확인하고, 꺼져 있거나 코드 변경 후라면 `./scripts/server-ctl.sh restart`를 실행한다.
2. **엔드포인트 스모크 호출**:
   - `./scripts/smoke-test.sh /api/v1/<도메인>`을 실행하여 HTTP 응답 코드와 JSON 본문을 확인한다.
3. **POST/PUT 요청 검증**:
   - 데이터 생성/수정 테스트가 필요하면 `curl -s -X POST http://localhost:8080/api/v1/samples -H "Content-Type: application/json" -d '{"title":"테스트 항목","category":"DEMO","ownerId":1}'` 명령으로 JSON 본문을 전송하고 `ApiResponse`의 `"success": true` 여부를 확인한다.
4. **실패 시 자동 디버깅**:
   - 응답에 `"success": false`가 반환되면 JSON 내부의 `error.location` 필드와 `./logs/server.log` 마지막 40줄을 확인해 즉시 수정한다.
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > ".agents/workflows/debug-runtime.md"
---
description: 서버 기동 실패나 API 500 에러 발생 시 logs/server.log를 분석해 원인을 찾고 즉시 수정합니다.
---

# /debug-runtime — 런타임 로그 기반 자가 치유 워크플로우

1. **로그 및 서버 상태 수집**:
   - `./scripts/server-ctl.sh logs`를 실행해 `./logs/server.log`의 최근 50줄과 에러 스택트레이스를 확인한다.
2. **원인 진단**:
   - `com.hackathon.app` 패키지 내부에서 발생한 정확한 파일명과 줄 번호를 식별한다.
   - 만약 H2 DB 테이블 컬럼 타입 충돌이 원인이라면 `./scripts/server-ctl.sh reset-db`로 로컬 DB 파일을 초기화한 뒤 `DataInitializer`로 깨끗하게 재시딩할지 판단한다.
3. **핫픽스 및 재검증**:
   - 코드를 수정한 뒤 `./scripts/verify-fast.sh` → `./scripts/server-ctl.sh restart` → `./scripts/smoke-test.sh` 순서로 정상 동작을 확인한다.
   - 수정 완료 시 `./scripts/checkpoint.sh "fix: <수정한_에러_한글_요약>"`으로 커밋한다.
   - 만약 수정이 꼬여 이전 정상 상태로 되돌려야 한다면 `./scripts/checkpoint.sh --rollback`을 실행해 직전 체크포인트로 즉시 복구한다.
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > ".agents/workflows/handoff.md"
---
description: 대화가 길어져 에이전트가 느려지거나 환각이 생기기 전에 현재 상태를 TASKS.md에 압축 기록하고 새 대화창 전환용 프롬프트를 생성합니다.
---

# /handoff — 대화 세션 리셋 및 컨텍스트 핸드오프

한 대화창에서 기능 2~3개를 구현하면 컨텍스트가 길어져 속도와 정확도가 떨어집니다. 아래 절차로 상태를 인계합니다:

1. **현재 상태 스냅샷 갱신**:
   - 현재 구현 완료된 엔티티 목록, API 엔드포인트 목록, 그리고 가장 최근 해결한 이슈나 주의사항을 `docs/TASKS.md` 상단의 `## Current Session State` 섹션에 10줄 이내로 최신화한다.
2. **안전 체크포인트 커밋**:
   - `./scripts/verify-fast.sh` 실행 후 `./scripts/checkpoint.sh "chore: 대화 세션 핸드오프 상태 스냅샷 저장"`으로 현재 작업 상태를 커밋한다.
3. **새 대화창 시작 프롬프트 출력**:
   - 사용자에게 **"새 대화(New Conversation) 버튼을 누르고 아래 문장을 복사해 붙여넣으세요"**라고 안내한다:
     > `docs/SPEC.md와 docs/TASKS.md의 Current Session State를 읽고, 다음 미완료 태스크를 /implement-api 워크플로우로 이어서 진행해줘.`
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > ".agents/workflows/implement-api.md"
---
description: TASKS.md의 다음 미완료 항목 1개를 골든 샘플 패턴으로 구현하고, 시딩 데이터 추가, 서버 재기동, 스모크 테스트, Git 체크포인트까지 자동 수행합니다.
---

# /implement-api — 원스톱 기능 구현 및 검증 루프

1. **태스크 확인**:
   - `docs/TASKS.md`와 `docs/SPEC.md`를 읽고 첫 번째 미완료 항목(`[ ]`)을 진행 중(`[/]`)으로 표시한다.
2. **골든 샘플 복제 및 컨벤션 준수 구현**:
   - `src/main/java/com/hackathon/app/sample/` 패키지의 구조를 참고하여 `com.hackathon.app.<도메인>` 패키지 안에 `Entity`, `Repository`, `Service`(Java 21 `record` DTO 포함), `Controller`(한글 `@Tag`, `@Operation` 및 `/api/v1/복수형-케밥-케이스` 적용)를 작성한다.
3. **데모용 초기 데이터 시딩 추가**:
   - `src/main/java/com/hackathon/app/common/DataInitializer.java`에 신규 엔티티의 초기 데모 데이터 3건 이상을 `if (repo.count() == 0)` 조건으로 추가한다.
4. **1단계 고속 컴파일 검증**:
   - `./scripts/verify-fast.sh`를 실행한다. 컴파일 에러가 발생하면 즉시 수정하고 통과할 때까지 반복한다.
5. **2단계 안전 서버 재기동 및 스모크 테스트**:
   - `./scripts/server-ctl.sh restart`를 실행해 기존 8080 좀비 프로세스를 정리하고 최신 코드로 서버를 띄운다.
   - `./scripts/smoke-test.sh <신규_API_경로>`를 실행해 실제 200 OK 응답과 시딩 데이터가 정상 조회되는지 확인한다.
6. **체크포인트 저장 및 보고**:
   - `docs/TASKS.md`에서 해당 항목을 완료(`[x]`)로 변경한다.
   - `./scripts/checkpoint.sh "feat: <구현한_기능_한글_요약>"`을 실행해 정돈된 Git 커밋을 남긴다.
   - 사용자에게 구현된 API 경로와 브라우저에서 바로 클릭해 테스트할 수 있는 Swagger 주소(`http://localhost:8080/swagger`)를 안내한다.
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > ".agents/workflows/spec.md"
---
description: 해커톤 아이디어를 받아 DB 테이블 설계(SPEC.md)와 15분 단위 구현 체크리스트(TASKS.md)를 생성합니다. (코드 수정 없음)
---

# /spec — 해커톤 기획 및 태스크 분해 워크플로우

사용자가 서비스 아이디어나 요구사항을 입력하면 **코드를 바로 작성하지 말고** 아래 순서만 수행한다:

1. **핵심 도메인 단순화**:
   - 사용자의 아이디어를 해커톤 시간 내에 완주 가능한 **핵심 엔티티 2~4개**와 **핵심 API 5~8개**로 압축한다.
   - 모든 엔티티는 연관관계(`@ManyToOne` 등) 없이 단순 ID 참조 필드로만 설계한다.
2. **`docs/SPEC.md` 업데이트**:
   - 서비스 한 줄 요약, 엔티티별 필드 표(`snake_case` 복수형 테이블명 포함), API 엔드포인트 목록(`/api/v1/kebab-case`), 데모 시나리오 3단계를 `docs/SPEC.md`에 작성한다.
3. **`docs/TASKS.md` 생성**:
   - 각 API 또는 도메인 단위로 15~20분 내에 구현·검증 가능한 체크리스트(`- [ ] Task 1: ...`)를 `docs/TASKS.md`에 작성한다.
4. **기획 스냅샷 커밋 및 확인 요청**:
   - `./scripts/checkpoint.sh "chore: 해커톤 서비스 기획(SPEC.md) 및 태스크 목록 정의"`를 실행한다.
   - 작성된 명세와 태스크 목록을 요약해 보여주고, 첫 번째 태스크를 `/implement-api`로 시작할지 물어본다.
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

cat << 'EOF_HARNESS_FILE' > "GEMINI.md"
# Solo Hackathon Harness — Spring Boot 3 (Java 21)

이 프로젝트는 1인 단기 해커톤을 위해 설계된 **초단순 방어형 Spring Boot 3.x (Java 21) 백엔드 하네스**입니다.
에이전트는 모든 코드 작성 및 실행 시 아래 규칙을 최우선으로 준수해야 합니다.

## 1. 사용자 맞춤형 커뮤니케이션 & 자율 실행 원칙
- 사용자는 Spring 내부 메커니즘에 익숙하지 않다. 설명할 때 복잡한 프레임워크 용어(영속성 컨텍스트, 프록시, 빈 생명주기 등)를 나열하지 말고 **직관적인 비즈니스 동작과 확인 방법(Swagger URL 등)**만 간결하게 안내한다.
- 컴파일 확인, 서버 재시작, API 동작 테스트는 사용자에게 떠넘기지 말고 에이전트가 직접 `./scripts/verify-fast.sh`, `./scripts/server-ctl.sh`, `./scripts/smoke-test.sh`를 실행해 끝까지 검증한 뒤 결과만 보고한다.

## 2. 초보자 방어형 Spring 코딩 절대 규칙 (Easy-Spring Mode)
1. **JPA 연관관계 어노테이션 전면 금지**:
   - `@OneToMany`, `@ManyToOne`, `@OneToOne`, `@ManyToMany`를 **절대 사용하지 않는다**.
   - 다른 엔티티를 참조할 때는 무조건 단순 ID 값(`private Long userId;`, `private Long categoryId;`)으로만 필드를 선언하고 Repository에서 ID로 직접 조회한다.
2. **Spring Security 추가 절대 금지**:
   - `spring-boot-starter-security` 의존성을 절대 추가하지 않는다.
   - 해커톤 데모용 사용자 식별이 필요하면 요청 헤더(`X-Demo-User-Id`, 기본값 `1`) 또는 쿼리 파라미터로 단순 처리한다.
3. **Java 21 `record` 기반 DTO 작성**:
   - 모든 Request/Response DTO는 Lombok `@Data`/`@Builder` 대신 Java 21 표준 `public record`를 사용하여 간결하게 작성한다.
4. **평면(Flat) 패키지 & 단일 계층 유지**:
   - `*ServiceImpl` 같은 인터페이스 분리를 금지한다.
   - 새로운 도메인을 만들 때는 반드시 **`src/main/java/com/hackathon/app/sample` 패키지의 골든 샘플 코드 구조와 어노테이션 패턴을 그대로 복제**하여 작성한다.
5. **초기 시딩 데이터 의무 갱신 (`DataInitializer.java`)**:
   - 새로운 Entity와 Repository를 만들면 반드시 `common/DataInitializer.java`에 데모 시연용 초기 샘플 데이터 3건 이상을 함께 추가한다.
6. **정돈된 코드 네이밍 & Git 커밋 컨벤션 준수 (`.agents/rules/conventions-and-git.md`)**:
   - REST URI는 `/api/v1/<복수형-케밥-케이스>`, 테이블명은 `snake_case` 복수형, Swagger 어노테이션(`@Tag`, `@Operation`)은 한글로 통일한다.
   - 모든 커밋은 검증 통과 후 `./scripts/checkpoint.sh "<타입>: <한글 요약>"` (`feat`, `fix`, `seed`, `chore`) 형식으로 기록한다.

## 3. 표준 검증 및 서버 제어 명령어
- **1단계 초고속 문법/타입 검증 (1~2초)**: `./scripts/verify-fast.sh`
- **좀비 프로세스 방지 안전 재기동**: `./scripts/server-ctl.sh restart`
- **2단계 런타임 스모크 테스트**: `./scripts/smoke-test.sh <엔드포인트_경로>`
- **검증 완료 후 Git 체크포인트 저장**: `./scripts/checkpoint.sh "feat: <구현_기능_요약>"`
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

cat << 'EOF_HARNESS_FILE' > "docs/SPEC.md"
# Service Specification (Single Source of Truth)

> 해커톤 시작 시 `/spec` 명령어를 실행하면 에이전트가 이 파일을 서비스 기획에 맞게 채웁니다.

## 1. 서비스 한 줄 요약
- **서비스명**: (예: AI 기반 개인 맞춤형 해커톤 프로토타입)
- **핵심 가치**: 심사위원에게 3분 안에 보여줄 핵심 유저 플로우 1가지에 집중

## 2. 엔티티 설계 (연관관계 어노테이션 없이 단순 ID 참조)
| 엔티티명 | 테이블명 (`snake_case` 복수형) | 주요 필드 | 비고 (시딩 데이터 포함 여부) |
| :--- | :--- | :--- | :--- |
| `SampleItem` | `sample_items` | `id (Long)`, `title (String)`, `category (String)`, `ownerId (Long)`, `createdAt (LocalDateTime)` | 기본 제공 골든 샘플 (`DataInitializer`에 3건 시딩됨) |

## 3. 핵심 API 목록 (`/api/v1/복수형-케밥-케이스`)
| Method | Endpoint | 설명 | 요청 DTO (`record`) | 응답 데이터 |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/samples` | 전체 샘플 목록 조회 (카테고리 필터 지원) | Query: `category` (선택) | `List<SampleResponse>` |
| `POST` | `/api/v1/samples` | 신규 샘플 항목 생성 | `CreateSampleRequest` | `SampleResponse` |
| `GET` | `/api/v1/samples/{id}` | 단건 상세 조회 | Path: `id` | `SampleResponse` |
| `DELETE` | `/api/v1/samples/{id}` | 항목 삭제 | Path: `id` | `Void` |
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > "docs/TASKS.md"
# Hackathon Task Queue & Session State

## Current Session State
- **최근 완료 작업**: 하네스 초기 세팅 및 골든 샘플(`SampleItem` CRUD + `DataInitializer` 시딩) 구축 완료
- **현재 활성 엔티티**: `SampleItem` (`sample_items`)
- **현재 활성 API**: `GET/POST /api/v1/samples`, `GET/DELETE /api/v1/samples/{id}`
- **다음 우선순위**: `/spec`으로 해커톤 아이디어 구체화 후 첫 번째 도메인 구현

## Implementation Checklist
- [x] Task 0: 기본 하네스 및 골든 샘플(`sample` 패키지) 동작 확인
- [ ] Task 1: (`/spec` 워크플로우 실행 시 이곳에 15분 단위 태스크가 자동 생성됩니다)
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > "scripts/checkpoint.sh"
#!/usr/bin/env bash
# checkpoint.sh — 컨벤션 자동 보정 Git 체크포인트 저장 및 원클릭 롤백 스크립트
# 사용법:
#   저장: ./scripts/checkpoint.sh "feat: 샘플 API 구현"
#   복구: ./scripts/checkpoint.sh --rollback
set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git init -q
  git branch -M main 2>/dev/null || true
  git add -A
  git commit -q -m "chore: 해커톤 하네스 초기 세팅"
fi

if [ "${1:-}" = "--rollback" ]; then
  echo "⏪ [checkpoint] 직전 정상 체크포인트로 코드를 되돌립니다..."
  git reset --hard HEAD
  git clean -fd
  echo "✅ [checkpoint] 복구 완료: $(git log -1 --oneline)"
  exit 0
fi

RAW_MSG="${1:-chore: 검증 완료 체크포인트 저장}"

# 접두사(feat:, fix:, seed:, chore:, refactor:, docs:)가 없으면 자동으로 'feat: '를 붙여 히스토리를 정돈
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
# server-ctl.sh — 8080 좀비 프로세스 자동 정리 및 Spring Boot 백그라운드 제어기
# 사용법: ./scripts/server-ctl.sh {start|stop|restart|status|logs|reset-db}
set -euo pipefail

PORT=8080
LOG_DIR="./logs"
LOG_FILE="${LOG_DIR}/server.log"
PID_FILE="${LOG_DIR}/server.pid"
HEALTH_URL="http://localhost:${PORT}/actuator/health"

mkdir -p "${LOG_DIR}" ./data

find_port_pids() {
  if command -v lsof >/dev/null 2>&1; then
    lsof -ti:"${PORT}" 2>/dev/null || true
  elif command -v fuser >/dev/null 2>&1; then
    fuser "${PORT}/tcp" 2>/dev/null || true
  else
    ps aux | grep "[j]ava.*hackathon" | awk '{print $2}' || true
  fi
}

stop_server() {
  echo "🛑 [server-ctl] ${PORT}번 포트 점유 프로세스 확인 및 정리 중..."
  if [ -f "${PID_FILE}" ]; then
    SAVED_PID=$(cat "${PID_FILE}" || true)
    if [ -n "${SAVED_PID}" ] && kill -0 "${SAVED_PID}" 2>/dev/null; then
      kill -9 "${SAVED_PID}" 2>/dev/null || true
    fi
    rm -f "${PID_FILE}"
  fi

  PIDS=$(find_port_pids)
  if [ -n "${PIDS}" ]; then
    for pid in ${PIDS}; do
      echo "   -> 좀비 프로세스 강제 종료 (PID: ${pid})"
      kill -9 "${pid}" 2>/dev/null || true
    done
    sleep 1
  fi
  echo "✅ [server-ctl] 포트 ${PORT} 정리 완료."
}

start_server() {
  PIDS=$(find_port_pids)
  if [ -n "${PIDS}" ]; then
    echo "⚠️ [server-ctl] 이미 ${PORT}번 포트가 사용 중입니다 (PID: ${PIDS}). 먼저 정리를 수행합니다."
    stop_server
  fi

  echo "🚀 [server-ctl] Spring Boot 서버 백그라운드 기동 중..."
  : > "${LOG_FILE}"
  nohup ./gradlew bootRun --daemon -q > "${LOG_FILE}" 2>&1 &
  NEW_PID=$!
  echo "${NEW_PID}" > "${PID_FILE}"

  echo "⏳ [server-ctl] 서버 Health 체크 대기 중 (${HEALTH_URL})..."
  MAX_WAIT=30
  for ((i=1; i<=MAX_WAIT; i++)); do
    if curl -fsS "${HEALTH_URL}" 2>/dev/null | grep -q '"status":"UP"'; then
      echo "✅ [server-ctl] 서버 기동 완료! (${i}초 소요)"
      echo "   👉 Swagger UI: http://localhost:${PORT}/swagger"
      echo "   👉 H2 DB 콘솔: http://localhost:${PORT}/h2-console (JDBC URL: jdbc:h2:file:./data/hackathon-db)"
      return 0
    fi
    sleep 1
  done

  echo "❌ [server-ctl] ${MAX_WAIT}초 내에 서버가 정상 기동되지 않았습니다. 최근 에러 로그:"
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
    echo "사용법: $0 {start|stop|restart|status|logs|reset-db}"
    exit 1
    ;;
esac
EOF_HARNESS_FILE
chmod +x "scripts/server-ctl.sh"

cat << 'EOF_HARNESS_FILE' > "scripts/smoke-test.sh"
#!/usr/bin/env bash
# smoke-test.sh — 2단계 로컬 API 런타임 스모크 검증기
# 사용법: ./scripts/smoke-test.sh [/api/v1/samples]
set -euo pipefail

TARGET_PATH="${1:-/api/v1/samples}"
BASE_URL="http://localhost:8080"

echo "🌐 [1/2] 서버 상태 확인 중..."
if ! curl -fsS "${BASE_URL}/actuator/health" >/dev/null 2>&1; then
  echo "⚠️ 서버가 꺼져 있어 자동으로 기동합니다..."
  ./scripts/server-ctl.sh start
fi

echo "🌐 [2/2] GET ${BASE_URL}${TARGET_PATH} 호출 중..."
HTTP_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" "${BASE_URL}${TARGET_PATH}")
HTTP_BODY=$(echo "${HTTP_RESPONSE}" | sed -e 's/HTTP_STATUS\:.*//g')
HTTP_STATUS=$(echo "${HTTP_RESPONSE}" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

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
# verify-fast.sh — 1단계 초고속 컴파일 & 정적 규칙 검증기 (1~2초 소요)
set -euo pipefail

echo "🔍 [1/2] 금지된 패턴(JPA 연관관계, ServiceImpl 분리) 정적 검사 중..."
if grep -rnE "@(OneToMany|ManyToOne|OneToOne|ManyToMany)" src/main/java/ 2>/dev/null; then
  echo "❌ [규칙 위반] JPA 연관관계 어노테이션이 감지되었습니다! 단순 ID 필드(Long xxxId)로 변경하세요."
  exit 1
fi

if find src/main/java/ -name "*ServiceImpl.java" | grep -q .; then
  echo "❌ [규칙 위반] 불필요한 *ServiceImpl 클래스가 감지되었습니다! 단일 @Service 클래스로 작성하세요."
  exit 1
fi

echo "🔍 [2/2] Gradle Daemon 고속 컴파일 검증 중..."
if ! OUTPUT=$(./gradlew compileJava compileTestJava --daemon --console=plain 2>&1); then
  echo "❌ [컴파일 실패] 핵심 에러 내역:"
  echo "${OUTPUT}" | grep -E "(error:|warning:|FAILED|Exception)" -A 3 | head -n 35
  exit 1
fi

echo "✅ [verify-fast] 코드 컨벤션 및 컴파일 검증 통과!"
EOF_HARNESS_FILE
chmod +x "scripts/verify-fast.sh"

cat << 'EOF_HARNESS_FILE' > "settings.gradle"
rootProject.name = 'hackathon-app'
EOF_HARNESS_FILE

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

import java.time.LocalDateTime;

/**
 * 모든 API 응답을 일관된 JSON 구조로 감싸는 Java 21 record 래퍼.
 */
public record ApiResponse<T>(
        boolean success,
        T data,
        ErrorDetail error,
        LocalDateTime timestamp
) {
    public record ErrorDetail(
            String message,
            String exceptionType,
            String location
    ) {}

    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, data, null, LocalDateTime.now());
    }

    public static <T> ApiResponse<T> fail(String message, String exceptionType, String location) {
        return new ApiResponse<>(
                false,
                null,
                new ErrorDetail(message, exceptionType, location),
                LocalDateTime.now()
        );
    }
}
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > "src/main/java/com/hackathon/app/common/CorsConfig.java"
package com.hackathon.app.common;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * 해커톤 후반부 웹/모바일 프론트엔드 연동 시 CORS 에러가 발생하지 않도록 모든 출처를 허용.
 */
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
 * 새로운 도메인(Entity/Repository)을 추가할 때마다 에이전트는 아래 run() 메서드에 시딩 로직을 추가해야 합니다.
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
        if (sampleItemRepository.count() > 0) {
            log.info("[DataInitializer] SampleItem 데이터가 이미 존재하여 시딩을 건너뜁니다. (현재 {}건)", sampleItemRepository.count());
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
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Arrays;
import java.util.stream.Collectors;

/**
 * 에이전트가 에러 원인과 코드 위치(파일명:줄번호)를 응답 JSON에서 즉시 읽고 자가 수정할 수 있게 돕는 전역 예외 핸들러.
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiResponse<Void>> handleBadRequest(IllegalArgumentException ex) {
        log.warn("[BadRequest] {}", ex.getMessage());
        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.fail(ex.getMessage(), ex.getClass().getSimpleName(), extractAppLocation(ex)));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleValidation(MethodArgumentNotValidException ex) {
        String message = ex.getBindingResult().getFieldErrors().stream()
                .map(err -> err.getField() + ": " + err.getDefaultMessage())
                .collect(Collectors.joining(", "));
        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.fail(message, "ValidationException", extractAppLocation(ex)));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleUnexpected(Exception ex) {
        log.error("[UnhandledException] ", ex);
        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.fail(ex.getMessage(), ex.getClass().getSimpleName(), extractAppLocation(ex)));
    }

    private String extractAppLocation(Throwable ex) {
        return Arrays.stream(ex.getStackTrace())
                .filter(frame -> frame.getClassName().startsWith("com.hackathon.app"))
                .limit(2)
                .map(frame -> frame.getFileName() + ":" + frame.getLineNumber() + " (" + frame.getMethodName() + ")")
                .collect(Collectors.joining(" <- "));
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
                        .version("v1.0")
                        .description("프론트엔드 없이 브라우저에서 즉시 테스트 가능한 해커톤 API 문서 (/swagger)"));
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
 * - JPA 연관관계(@ManyToOne 등)를 절대 사용하지 않고 ownerId처럼 단순 Long 값으로 참조합니다.
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

cat << 'EOF_HARNESS_FILE' > "src/main/java/com/hackathon/app/sample/SampleItemController.java"
package com.hackathon.app.sample;

import com.hackathon.app.common.ApiResponse;
import com.hackathon.app.sample.SampleItemService.CreateSampleRequest;
import com.hackathon.app.sample.SampleItemService.SampleResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * [골든 샘플 Controller]
 * - 모든 신규 도메인 컨트롤러는 이 클래스의 어노테이션과 ApiResponse 반환 패턴을 그대로 복제합니다.
 */
@Tag(name = "01. Sample API (골든 샘플)", description = "에이전트가 신규 기능 구현 시 복제할 표준 CRUD 템플릿")
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

    @Operation(summary = "샘플 삭제")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> deleteSample(@PathVariable Long id) {
        sampleItemService.delete(id);
        return ApiResponse.ok(null);
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
 * - 불필요한 ServiceImpl 분리 없이 단일 클래스에서 비즈니스 로직과 Record DTO를 관리합니다.
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
    public void delete(Long id) {
        if (!sampleItemRepository.existsById(id)) {
            throw new IllegalArgumentException("삭제할 항목이 존재하지 않습니다: " + id);
        }
        sampleItemRepository.deleteById(id);
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
    # 별도 DB 설치가 필요 없으면서 서버 재시작 시에도 데이터가 증발하지 않는 로컬 파일 모드
    url: jdbc:h2:file:./data/hackathon-db;AUTO_SERVER=TRUE;MODE=MySQL
    driver-class-name: org.h2.Driver
    username: sa
    password:
  h2:
    console:
      enabled: true
      path: /h2-console
      settings:
        web-allow-others: true
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
        include: health,info,mappings

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

echo "✅ [하네스_해커톤_v1] 전체 29개 파일(규칙, 워크플로우, 스크립트, Spring Boot 골든 샘플) 생성이 완료되었습니다!"
