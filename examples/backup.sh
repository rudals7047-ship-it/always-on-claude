#!/bin/zsh
# 작업 폴더 일일 백업 → 클라우드 동기화 폴더(예: iCloud Drive). 암호화 없이 서비스 기본 보안을 쓰는 단순 방식.
# - 매일 새벽 스케줄러 실행. 날짜별 폴더(Backup/YYYY-MM-DD)에 복사하고 최근 7개만 유지.
# - 제외: 가상환경·빌드 산출물·다시 받을 수 있는 대용량. 토큰·봇 설정은 작업 폴더 밖에 두므로 포함되지 않는다.
# - 실패하면 텔레그램으로 알린다. 성공 기록은 state/logs/backup.last. 사용법: backup-icloud.sh [--dry-run]
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
# launchd 자식은 iCloud Drive 쓰기 권한이 없어(L-083) 권한이 있는 tmux 서버 안에서 다시 실행한다.
# (macOS) 스케줄러 자식 프로세스는 iCloud 폴더 권한이 없을 수 있다. 그러면 권한을 준 터미널/tmux 서버 안에서
# 같은 스크립트를 다시 실행하도록 우회하는 래퍼(예: tmux run-shell)를 이 자리에 둔다(L-083).
W="${ASSISTANT_HOME:-$HOME/assistant}"; LOG="$W/state/logs"; mkdir -p "$LOG"
DEST_ROOT="${BACKUP_DEST:-$HOME/Library/Mobile Documents/com~apple~CloudDocs/Backup}"
KEEP=7; TODAY=$(date +%F); DRY=0; [ "$1" = "--dry-run" ] && DRY=1
fail() { print -r -- "$(date '+%F %T') [backup] 실패: $1" >> "$LOG/briefing.log"
  [ -n "$NO_TG" ] && { print -r -- "실패: $1"; exit 1; }
  source "$W/scripts/tg-lib.sh"; tg_send_text "⚠️ 백업 실패: $1 (로그: $LOG/briefing.log)"; exit 1; }
mkdir -p "$DEST_ROOT" 2>/dev/null || fail "iCloud Drive 폴더를 만들 수 없음(권한 또는 iCloud 로그아웃)"
D="$DEST_ROOT/$TODAY"
OPTS=(-a --delete --exclude=.venv --exclude=.build --exclude=node_modules --exclude=__pycache__ --exclude=.DS_Store --exclude=.git)
[ $DRY -eq 1 ] && { rsync $OPTS -n --stats "$W/" "$D/" | grep -E "Number of files|Total file size"; exit 0; }
rsync $OPTS "$W/" "$D/" 2>"$LOG/backup.err" || fail "rsync 오류 $(head -c 200 "$LOG/backup.err")"
# 오래된 백업 정리(날짜 폴더 7개 초과분만, 이 백업 폴더 안에서만)
DIRS=("${(@f)$(ls -1d "$DEST_ROOT"/????-??-?? 2>/dev/null | sort)}")
[ ${#DIRS} -gt $KEEP ] && for old in ${DIRS[1,$(( ${#DIRS} - KEEP ))]}; do rm -rf -- "$old"; done
N=$(find "$D" -type f | wc -l | tr -d ' '); K=$(du -sk "$D" | awk '{print $1}')
print -r -- "$(date '+%F %T') 파일 ${N}개, ${K}KB, 위치 $D" > "$LOG/backup.last"
print -r -- "$(date '+%F %T') [backup] 완료 ${N}개 ${K}KB" >> "$LOG/briefing.log"
