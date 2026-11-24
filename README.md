# Always-on Claude

**텔레그램으로 부르는 24시간 개인 AI 비서 — "Mimir"를 만들며 깨진 것들**

항상 켜 둔 Mac에서, 휴대폰 메신저(텔레그램)로 요청하면 일정·미리 알림·메일·메시지를 챙기고 결과를 돌려주는 **개인용 AI 비서**를 Claude Code로 만든 기록입니다. 코드 저장소가 아니라 **설계와 시행착오를 정리한 문서 저장소**입니다. 그대로 복제하는 용도가 아니라, 비슷한 것을 만들려는 분이 같은 함정을 피하도록 돕는 것이 목적입니다.

> ⚠️ **면책**: 개인 사용 기록이며 보증하지 않습니다. 메신저·메일 자동화는 서비스 약관 위반이나 계정 제재의 가능성이 있고(특히 비공식 방식), 타인의 대화를 다루는 일이라 법적·윤리적 책임은 각자에게 있습니다. 여기에 실제 개인정보·설정·키는 포함돼 있지 않습니다(자세한 내용은 [보안·개인정보](docs/security-and-privacy.md)).

## 한눈에 보기
| 질문 | 답 |
|---|---|
| 무엇인가 | 메신저로 요청 → 맥에서 실행 → 결과를 메신저로 회신하는 상시 비서 |
| 바탕 | Claude Code(CLI), 기존 구독 범위(API 키 방식 아님) |
| 항상 켜 두는 법 | tmux 세션 + 감독 스크립트 + 매일 정해진 시각 재시작 |
| 정기 업무 | LaunchAgent가 하루 2번 보고(아침·저녁)와 백그라운드 감시를 실행 |
| 안전 원칙 | 되돌리기 쉬운 일은 먼저 하고 나중에 보고, 되돌리기 어려운 일(발송·삭제·금전·권한)만 승인 |
| 공개 범위 | 구조 설명 + 일반화한 교훈 9개. 설정·코드 원본·기억 파일은 제외 |

## 문서
- [구조](docs/architecture.md): 세션, 정기 작업, 승인, 기억이 어떻게 맞물리는가
- [설계 원칙](docs/design-principles.md): 자율성과 안전을 어떻게 나눴는가
- [보안·개인정보](docs/security-and-privacy.md): 무엇을 일부러 공개하지 않았고, 어떤 위험을 다뤘는가
- [한계와 미확인](docs/limitations.md): 아직 검증하지 못한 것
- 교훈 ([docs/lessons/](docs/lessons/))

| 교훈 | 요약 |
|---|---|
| [L-083](docs/lessons/L-083-launchd-job-lacks-tcc-use-tmux-proxy.md) | 스케줄러(launchd)로 돌린 스크립트만 macOS 권한이 없다 → 권한 있는 프로세스 경유 |
| [L-084](docs/lessons/L-084-llm-worker-relative-path-false-done.md) | 무인 LLM 작업자가 엉뚱한 폴더를 집고 "완료"라고 보고한다 |
| [L-085](docs/lessons/L-085-telegram-approval-reply-keyboard.md) | 봇 승인 버튼: 폴링 독점 때문에 인라인 콜백을 못 받는다 → 답장 키보드 |
| [L-098](docs/lessons/L-098-third-party-ui-automation-audit-and-side-effects.md) | 서드파티 UI 자동화 도입 전 점검: 소스 감사, 읽음 처리 부작용, 권한 최소화 |
| [L-100](docs/lessons/L-100-dedupe-at-write-path-not-in-prompt.md) | 중복 등록 방지는 지시문이 아니라 쓰기 경로에 넣는다 |
| [L-101](docs/lessons/L-101-approval-noise-is-workflow-not-allowlist.md) | 승인이 잦을 때 허용 목록 손질보다 역할 분리·정책 정합성이 먼저다 |
| [L-102](docs/lessons/L-102-two-daily-reports-and-separate-watchers.md) | 정기 보고는 하루 2번으로 모으고 감시는 분리한다 |
| [L-103](docs/lessons/L-103-ops-logs-outside-user-cleanup-scope.md) | 운영 로그·상태는 정리 앱이 건드리는 사용자 라이브러리 밖에 둔다 |
| [L-104](docs/lessons/L-104-usage-limit-retry-and-fuzzy-output-gates.md) | 한도 실패는 기다려 재시도, 알림은 완료 기록으로, 모델 출력 판정은 느슨하게 |

## 라이선스
이 문서는 [CC BY 4.0](LICENSE)입니다. 출처만 밝히면 자유롭게 공유·수정할 수 있습니다.
