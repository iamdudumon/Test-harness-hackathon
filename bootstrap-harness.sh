#!/usr/bin/env bash
set -euo pipefail
echo '🚀 [하네스_해커톤_v1] Spring Boot 3 (Java 21) + Antigravity 하네스 파일 생성을 시작합니다...'
rm -rf src/main/java/* src/test/java/*
rm -f src/main/resources/application.properties build.gradle.kts

cat << 'EOF_HARNESS_FILE' > "GEMINI.md"
# Solo Hackathon Harness — Spring Boot 3 (Java 21)

이 프로젝트는 1인 단기 해커톤을 위해 설계된 **초단순 방어형 Spring Boot 3.x (Java 21) 백엔드 하네스**입니다.
에이전트는 모든 코드 작성 및 실행 시 아래 규칙을 최우선으로 준수해야 합니다.

## 1. 사용자 맞춤형 커뮤니케이션 & 율 실행 원칙
- 사용자는 Spring 내부 메커니즘에 익숙하지 않다. 설명할 때 복잡한 프레임워크 용어(영속성 컨텍스트, 프록시, 빈 생명주기 등)를 나열하지 말고 **직관적인 비즈니스 동작과 확인 방(Swagger URL 등)**만 간결하게 안내한다.
- 컴파일 확인, 버 재시작, API 동작 테스트는 사용자에게 떠넘기지 말고 에이전트가 직접 `./scripts/verify-fast.sh`, `./scripts/server-ctl.sh`, `./scripts/smoke-test.sh`를 행해 끝까지 검증한 뒤 결과만 보고한다.

## 2. 초보자 방어형 Spring 코딩 절대  (Easy-Spring Mode)
1. **JPA 연관관계 어노테이션 전면 금지**: `@OneToMany`, `@ManyToOne`, `@OneToOne`, `@ManyToMany`를 절대 사용하지 않 단순 ID 값(`private Long userId;`)으로만 참조한다.
2. **Spring Security 추가 절대 금지**: `spring-boot-starter-security` 의존을 절대 추가하지 않는다.
3. **Java 21 `record` 기반 DTO 작성**: 모든 Request/Response DTO는 `public record`를 용한다.
4. **평면(Flat) 패키지 & 단일 계층 유지**: `*ServiceImpl` 분리를 금지하며, 새로운 도메인은 반드시 `src/main/java/com/hackathon/app/sample` 골든 샘플 조를 복제한다.
5. **초기 시딩 데이터 의무 갱신 (`DataInitializer.java`)**: 신규 Entity 추가 시 `common/DataInitializer.java`에 데모 시연 초기 샘플 데터 3건 이상을 함께 추가한다.
6. **정돈된 코드 네이밍 & Git 커밋 컨벤션 준수 (`.agents/rules/conventions-and-git.md`)**: REST URI는 `/api/v1/<복수형-케밥-케이스>`, 테이블명은 `snake_case` 복수형, Swagger 어노테이션은 한글로 통일하며 모든 커밋은 `./scripts/checkpoint.sh "<타입>: <한글 요약>"`으로 기록한다.
EOF_HARNESS_FILE

mkdir -p ".agents/rules" ".agents/workflows" ".agents/skills/api-smoke-test" "docs" "scripts" "logs" "data"

cat << 'EOF_HARNESS_FILE' > ".agents/rules/easy-spring.md"
---
description: Spring Boot 3 (Java 21) 코드 작성 시 상 적용되는 아키텍처 및 어노테이션 규칙
---
# Easy-Spring Implementation Rules
- 새 도메인은 `src/main/java/com/hackathon/app/sample/` 하위 4개 파일(`SampleItem`, `SampleItemRepository`, `SampleItemService`, `SampleItemController`)을 복제해 동일한 스타일로 작성한다.
- 모든 컨트러 답은 `ApiResponse.ok(data)`로 감싸서 반환한다.
- 엔티티가 추가되면 `common/DataInitializer.java`에 `if (repository.count() == 0)` 조건으로 데모용 초기 데이터를 반드시 추가한.
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > ".agents/rules/conventions-and-git.md"
---
description: 해톤 저장소와 API 문서를 깔끔하게 정돈하기 위한 경량 코드 컨벤션 및 Git 커밋 규칙
---
# Lightweight Code & Git Conventions
- **패키지 구조**: `com.hackathon.app.<도명>` 단위로 평면 배치한다 (`Entity`, `Repository`, `Service`, `Controller` 4개 일).
- **REST API 주소**: `/api/v1/<복수형-케밥-케이스>`로 통일한다.
- **DB 테이블명**: `@Table(name = "<snake_case_복수형>")`으로 명시한다.
- **서비스 메드명**: `findItems` / `findById` / `create` / `update` / `delete`로 일한다.
- **Swagger 한글 문서화**: 모 Controller에 `@Tag`, `@Operation`을 한글로 작성한다.
- **Git 브랜치 & 커밋**: 단일 `main` 브치에서 `<타입>: <한글 요약>` (`feat`, `fix`, `seed`, `chore`) 형식으로 `./scripts/checkpoint.sh`를 통해 커밋한다.
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > ".agents/rules/testing-and-runtime.md"
---
description: 빌드 지연과 포트 충돌을 막기 위한 검증 및 서버 실행 규칙
---
# Fast Verification & Server Control Rules
1. 코드 수정 직후에는 `./scripts/verify-fast.sh`를 실행해 컴파일 및 컨벤션 위반 여부를 먼저 인한다.
2. 직접 `./gradlew bootRun`을 실행지 말고 무조건 `./scripts/server-ctl.sh start|restart|stop|status`만 사용한다.
3. API 500 에러 기동 실패 시 `./logs/server.log`의 마지막 50줄을 읽어 원인을 파악한다.
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > ".agents/workflows/spec.md"
---
description: 해커톤 아이디어를 받아 DB 테이블 설계(SPEC.md)와 15분 단위 구현 체크리스트(TASKS.md)를 생성합니다.
---
1. 아이디어를 핵심 엔티티 2~4개(단순 ID 참조)와 핵심 API 5~8개로 압축한다.
2. `docs/SPEC.md`에 엔티티 표와 API 목록을 성한다.
3. `docs/TASKS.md`에 15분 단위 구현 체크리스트 작성하고 `./scripts/checkpoint.sh "chore: 해커톤 서스 기획 및 태스크 정의"`로 커밋한다.
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > ".agents/workflows/implement-api.md"
---
description: TASKS.md의 다음 미완료 항목 1개를 구현하고 시딩, 서버 재기동, 스모크 스트, Git 체크포인트까지 수행합니다.
---
1. `docs/TASKS.md`의 첫 미완 항목(`[ ]`)을 `[/]`로 변경한다.
2. `sample` 패키지를 복제해 규 도메인의 `Entity`, `Repository`, `Service`(Record DTO), `Controller`를 작성한다.
3. `common/DataInitializer.java`에 초기 데모 데이터 3건 이상을 추가한다.
4. `./scripts/verify-fast.sh` 통과 후 `./scripts/server-ctl.sh restart`와 `./scripts/smoke-test.sh <_API_경>`를 실행한다.
5. `docs/TASKS.md`를 `[x]`로 갱신하고 `./scripts/checkpoint.sh "feat: <구현_기능_요약>"`을 실행한 뒤 `http://localhost:8080/swagger` 주소를 안내한다.
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > ".agents/workflows/debug-runtime.md"
---
description: 서버 기동 실나 API 500 에러 발생 시 logs/server.log를 분석해 수정합니다.
---
1. `./scripts/server-ctl.sh logs`로 최근 에러 로그와 스택레이스를 확인한다.
2. 원인을 수정한 뒤 `./scripts/verify-fast.sh` -> `./scripts/server-ctl.sh restart` -> `./scripts/smoke-test.sh`로 검증하고 `./scripts/checkpoint.sh "fix: <수정_요약>"`으로 커밋한다.
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > ".agents/workflows/handoff.md"
---
description: 현재 행 상태를 TASKS.md에 압축 기록하고 새 대화창 전환용 프롬프트를 생성합니다.
---
1. 완료된 엔티티API 목록과 다음 할 일을 `docs/TASKS.md` 상단 `## Current Session State`에 갱신한다.
2. `./scripts/verify-fast.sh` 후 `./scripts/checkpoint.sh "chore: 대화 세션 핸드오프 냅샷 저장"`을 실행한다.
3.  대화창(New Conversation)에 붙여을 안내 문장을 출력한다: `docs/SPEC.md와 docs/TASKS.md의 Current Session State를 읽고, 다음 미완료 태스크를 /implement-api 워크플로우로 이어서 진행해줘.`
EOF_HARNESS_FILE

cat << 'EOF_HARNESS_FILE' > "scripts/server-ctl.sh"
#!/usr/bin/env bash
set -euo pipefail
PORT=8080
LOG_DIR="./logs"
LOG_FILE="${LOG_DIR}/server.log"
PID_FILE="${LOG_DIR}/server.pid"
HEALTH_URL="http://localhost:${PORT}/actuator/health"
mkdir -p "${LOG_DIR}" ./data

find_port_pids() {
  if command -v lsof >/dev/null 2>&1; then lsof -ti:"${PORT}" 2>/dev/null || true
    elif command -v fuser >/dev/null 2>&1; then fuser "${PORT}/tcp" 2>/dev/null || true
      else ps aux | grep "[j]ava.*hackathon" | awk '{print $2}' || true; fi
      }

      stop_server() {
        if [ -f "${PID_FILE}" ]; then
            SAVED_PID=$(cat "${PID_FILE}" || true)
                [ -n "${SAVED_PID}" ] && kill -9 "${SAVED_PID}" 2>/dev/null || true
                    rm -f "${PID_FILE}"
                      fi
                        PIDS=$(find_port_pids)
                          if [ -n "${PIDS}" ]; then
                              for pid in ${PIDS}; do kill -9 "${pid}" 2>/dev/null || true; done
                                  sleep 1
                                    fi
                                    }

                                    start_server() {
                                      stop_server
                                        : > "${LOG_FILE}"
                                          nohup ./gradlew bootRun --daemon -q > "${LOG_FILE}" 2>&1 &
                                            echo $! > "${PID_FILE}"
                                              for ((i=1; i<=30; i++)); do
                                                  if curl -fsS "${HEALTH_URL}" 2>/dev/null | grep -q '"status":"UP"'; then
                                                        echo "✅ 서 기동 완료! Swagger: http://localhost:${PORT}/swagger"
                                                              return 0
                                                                  fi
                                                                      sleep 1
                                                                        done
                                                                          tail -n 40 "${LOG_FILE}" || true
                                                                            return 1
                                                                            }

                                                                            case "${1:-status}" in
                                                                              start) start_server ;;
                                                                                stop) stop_server ;;
                                                                                  restart) stop_server && start_server ;;
                                                                                    status) curl -fsS "${HEALTH_URL}" && echo "🟢 UP" || echo "⚪ DOWN" ;;
                                                                                      logs) tail -n 50 "${LOG_FILE}" ;;
                                                                                        reset-db) stop_server && rm -rf ./data/hackathon-db* && start_server ;;
                                                                                        esac
                                                                                        EOF_HARNESS_FILE
                                                                                        chmod +x "scripts/server-ctl.sh"

                                                                                        cat << 'EOF_HARNESS_FILE' > "scripts/verify-fast.sh"
                                                                                        #!/usr/bin/env bash
                                                                                        set -euo pipefail
                                                                                        if grep -rnE "@(OneToMany|ManyToOne|OneToOne|ManyToMany)" src/main/java/ 2>/dev/null; then
                                                                                          echo "❌ [규칙 위반] JPA 연관관계 어노테이션 금지! 단 ID 필드를 사용하세요."
                                                                                            exit 1
                                                                                            fi
                                                                                            if find src/main/java/ -name "*ServiceImpl.java" | grep -q .; then
                                                                                              echo "❌ [칙 반] *ServiceImpl 분리 금지! 단일 @Service로 작성하세요."
                                                                                                exit 1
                                                                                                fi
                                                                                                ./gradlew compileJava compileTestJava --daemon --console=plain
                                                                                                echo "✅ [verify-fast] 코드 컨벤션 및 파일 검증 통과!"
                                                                                                EOF_HARNESS_FILE
                                                                                                chmod +x "scripts/verify-fast.sh"

                                                                                                cat << 'EOF_HARNESS_FILE' > "scripts/smoke-test.sh"
                                                                                                #!/usr/bin/env bash
                                                                                                set -euo pipefail
                                                                                                TARGET_PATH="${1:-/api/v1/samples}"
                                                                                                BASE_URL="http://localhost:8080"
                                                                                                curl -fsS "${BASE_URL}/actuator/health" >/dev/null 2>&1 || ./scripts/server-ctl.sh start
                                                                                                curl -f -s "${BASE_URL}${TARGET_PATH}" | head -c 300
                                                                                                echo -e "\n✅ [smoke-test] 정상 응답 확인 완료!"
                                                                                                EOF_HARNESS_FILE
                                                                                                chmod +x "scripts/smoke-test.sh"

                                                                                                cat << 'EOF_HARNESS_FILE' > "scripts/checkpoint.sh"
                                                                                                #!/usr/bin/env bash
                                                                                                set -euo pipefail
                                                                                                if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                                                                                                  git init -q && git branch -M main 2>/dev/null || true
                                                                                                    git add -A && git commit -q -m "chore: 해커톤 하네스 초기 세팅"
                                                                                                    fi
                                                                                                    if [ "${1:-}" = "--rollback" ]; then
                                                                                                      git reset --hard HEAD && git clean -fd
                                                                                                        echo "✅ 직전 체크포인트 복구 완료: $(git log -1 --oneline)"
                                                                                                          exit 0
                                                                                                          fi
                                                                                                          RAW_MSG="${1:-chore: 검증 완료 체크포인트 저장}"
                                                                                                          if [[ ! "${RAW_MSG}" =~ ^(feat|fix|seed|chore|refactor|docs):[[:space:]] ]]; then
                                                                                                            MSG="feat: ${RAW_MSG}"
                                                                                                            else
                                                                                                              MSG="${RAW_MSG}"
                                                                                                              fi
                                                                                                              git add -A
                                                                                                              git diff --cached --quiet || git commit -q -m "${MSG}"
                                                                                                              echo "✅ 체크포인트 저장: $(git log -1 --oneline)"
                                                                                                              EOF_HARNESS_FILE
                                                                                                              chmod +x "scripts/checkpoint.sh"
                                                                                                              
                                                                                                              echo '✅ [하네스_해커톤_v1] 본 규칙·워크플로우·스크립트 생성이 완료되었습니다!'
