#!/bin/zsh
# 하루 2번 정기 실행기. 사용법: run-daily.sh morning | evening
# - 각 단계는 독립 실행이라 하나가 실패해도 다음 단계가 돈다.
# - 단계 스크립트가 사용 한도 도달로 종료 코드 75를 내면, 해제 시각(+2분)까지 기다렸다가 그 단계를 1회만 재시도한다(L-104).
#   단계 스크립트는 한도 메시지("resets 5:10pm" 형태)를 $LOG/limit.last 에 써 두어야 한다.
ROOT="${ASSISTANT_HOME:-$HOME/assistant}"; S="$ROOT/scripts"; LOG="$ROOT/state/logs"; mkdir -p "$LOG"
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
rc=0

wait_for_reset() {   # limit.last 의 해제 시각까지 잔다. 6시간 넘게 걸리거나 읽을 수 없으면 1.
  local t hm now target
  t=$(sed -n 's/.*resets \([0-9:]*[ap]m\).*/\1/p' "$LOG/limit.last" 2>/dev/null | head -1); [ -n "$t" ] || return 1
  [[ "$t" == *:* ]] || t="${t/[ap]m/:00${t##*[0-9]}}"          # "5pm" → "5:00pm"
  hm=$(date -j -f "%I:%M%p" "$t" +%H:%M 2>/dev/null) || return 1  # macOS(BSD date). GNU date 는 date -d 로 바꿀 것
  now=$(date +%s); target=$(date -j -f "%F %H:%M" "$(date +%F) $hm" +%s) || return 1
  [ $target -le $now ] && target=$(( target + 86400 ))
  [ $(( target - now )) -gt 21600 ] && return 1
  sleep $(( target - now + 120 )); return 0
}

step() {   # $1=스크립트, 나머지=인자
  /bin/zsh "$@"; local r=$?
  if [ $r -eq 75 ] && wait_for_reset; then /bin/zsh "$@"; r=$?; fi
  [ $r -ne 0 ] && rc=1
  return 0
}

case "$1" in
  morning) step "$S/briefing.sh" morning ;;      # 예: 오늘 일정·마감 요약
  evening) step "$S/briefing.sh" evening         # 예: 내일 마감 + 하루 메시지 검토
           step "$S/review.sh" ;;
  *) print -u2 "usage: $0 morning|evening"; exit 2 ;;
esac
exit $rc
