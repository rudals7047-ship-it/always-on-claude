#!/bin/zsh
# 자기 점검(감시 대상과 분리된 스케줄러가 30분마다 실행). 문제가 있을 때만 알린다.
#  - 정기 작업의 성공은 launchd 종료 코드가 아니라 "오늘 완료 기록"으로 판단한다(종료 코드는 다음 성공 때까지 남아 오탐, L-104).
#  - 같은 문제는 6시간에 한 번만 알리고, 해소되면 "복구됨"을 한 번 알린다. 알림 문장의 줄바꿈은 $'\n' 로 만든다.
#  사용법: health-check.sh [--dry-run]
ROOT="${ASSISTANT_HOME:-$HOME/assistant}"; LOG="$ROOT/state/logs"; mkdir -p "$LOG"
STATE="$LOG/health.state"; touch "$STATE"
source "$ROOT/scripts/tg-lib.sh"
DRY=0; [ "$1" = "--dry-run" ] && DRY=1
NOW=$(date +%s); TODAY=$(date +%F); HM=$(date +%H%M)
typeset -A PROB
tmux has-session -t "${SESSION:-assistant}" 2>/dev/null || PROB[session]="상시 세션이 없습니다."
[ "$HM" -ge 0830 ] && ! grep -q "^$TODAY .*\[morning\] 완료" "$LOG/briefing.log" 2>/dev/null && PROB[fresh-morning]="오늘 아침 정기 작업의 완료 기록이 없습니다."
[ "$HM" -ge 1730 ] && ! grep -q "^$TODAY .*\[evening\] 완료" "$LOG/briefing.log" 2>/dev/null && PROB[fresh-evening]="오늘 저녁 정기 작업의 완료 기록이 없습니다."
USED=$(df -P / | awk 'NR==2{gsub("%","",$5); print $5}'); [ "${USED:-0}" -ge 90 ] && PROB[disk]="디스크 사용률 ${USED}%"
typeset -A LAST; while IFS=$'\t' read -r k t; do [ -n "$k" ] && LAST[$k]=$t; done < "$STATE"
ALERT=(); RECOVER=(); NEW=""
for k in ${(k)PROB}; do prev=${LAST[$k]:-0}
  if [ $(( NOW - prev )) -ge 21600 ]; then ALERT+=("• ${PROB[$k]}"); NEW+="$k\t$NOW\n"; else NEW+="$k\t$prev\n"; fi
done
for k in ${(k)LAST}; do [ -z "${PROB[$k]}" ] && RECOVER+=("• $k"); done
NL=$'\n'; MSG=""
[ ${#ALERT} -gt 0 ] && MSG+="자기 점검: 확인이 필요합니다${NL}${(F)ALERT}${NL}"
[ ${#RECOVER} -gt 0 ] && MSG+="복구됨${NL}${(F)RECOVER}${NL}"
if [ $DRY -eq 1 ]; then print "문제 ${#PROB}건, 알림 ${#ALERT}건, 복구 ${#RECOVER}건 (dry-run)"; exit 0; fi
if [ -n "$MSG" ]; then tg_send_text "$MSG" && print -n -- "$NEW" > "$STATE"; else print -n -- "$NEW" > "$STATE"; fi
