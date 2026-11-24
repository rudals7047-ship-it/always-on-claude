#!/bin/zsh
# AI 세션을 tmux 안에서 항상 켜 두는 감독 스크립트. launchd 가 이 스크립트를 KeepAlive 로 실행한다.
# - 세션이 죽으면 5초 뒤 다시 띄운다. 매일 RESTART_HOUR 시에 세션을 닫아 맥락을 초기화한다(다음 루프에서 새로 뜸).
# - AI_CMD 는 사용 중인 Claude Code 버전의 문서에 맞게 채운다(메신저 채널 연결 옵션 포함) [미확인: 버전마다 다름].
ROOT="${ASSISTANT_HOME:-$HOME/assistant}"; LOG="$ROOT/state/logs"; mkdir -p "$LOG"
SESSION="${SESSION:-assistant}"; RESTART_HOUR="${RESTART_HOUR:-04}"
AI_CMD="${AI_CMD:-claude}"      # 예: claude <메신저 채널 옵션> --permission-mode default
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
log() { print -r -- "$(date '+%F %T') $*" >> "$LOG/supervisor.log"; }
log "감독 시작"
while true; do
  if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux new-session -d -s "$SESSION" -c "$ROOT" "$AI_CMD" && log "tmux 세션 생성"
  fi
  if [[ "$(date +%H)" == "$RESTART_HOUR" && "$(date +%F)" != "$DID_RESTART_DAY" ]]; then
    log "정기 재시작: 맥락 초기화"; tmux kill-session -t "$SESSION" 2>/dev/null
    DID_RESTART_DAY=$(date +%F); sleep 10   # 같은 날 반복 재시작 방지, 다음 루프에서 새 세션이 뜬다
  fi
  sleep 5
done
