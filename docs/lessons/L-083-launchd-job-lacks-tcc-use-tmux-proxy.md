---
id: L-083
title: launchd로 돌린 스크립트만 캘린더·메시지 DB가 "authorization denied" (권한은 터미널/tmux에 있음) → tmux 서버 경유로 해결
type: pitfall
tags: [process, claude-workflow]
confidence: 확인
reuse: high
date: 2026-11-23
---

# L-083 launchd 작업은 터미널에 준 macOS 권한을 못 쓴다

**상황/증상:** 터미널·tmux·Claude 세션에서는 잘 읽히던 캘린더·메시지 DB가 launchd(LaunchAgent)로 돌리면 `authorization denied`로 실패한다. 실패 시 느린 대체 경로(AppleScript)로 넘어가면 작업이 멈춘 것처럼 보인다.

**원인:** [확인] macOS의 전체 디스크 접근 권한은 "책임 프로세스"(터미널·tmux 등)에 붙는다. launchd가 직접 띄운 `/bin/zsh`는 별도의 책임 프로세스라 그 권한이 없다. 미리 알림 폴더는 목록 조회부터 거부되어 zsh의 glob 오류로 스크립트가 중단되기도 했다.

**해결/방법:**
1. 권한을 이미 받은 tmux 서버 안에서 같은 스크립트를 다시 실행한다: `tmux run-shell -t <세션> "VIA_TMUX=1 /bin/zsh script > out; echo $? > out.rc"`, 끝나면 out을 읽는다(재귀 방지 환경변수 필수).
2. 읽기는 "직접 → tmux 경유 → 느린 앱 방식" 순으로 자동 전환하게 만든다.
3. glob은 `(N)` 한정자로 일치 없음을 오류가 아닌 빈 목록으로 처리한다.
4. 임시 LaunchAgent(RunAtLoad)로 실제 launchd 환경에서 시험하고 지운다. 터미널 시험만으로는 이 문제가 안 보인다.

**일반화:** "내 터미널에서 되는데 스케줄러에서만 안 된다"는 권한(TCC)·환경 차이를 먼저 의심한다. 보안 설정을 넓히기 전에, 이미 권한이 있는 프로세스의 자식으로 실행하는 방법이 있는지 본다.

**근거:** 2026-11-22 이벤트 감시가 launchd에서 멈춤, 2026-11-23 임시 LaunchAgent 시험에서 캘린더 0.8초·미리 알림 1.1초 정상.
