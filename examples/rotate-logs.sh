#!/bin/zsh
# 분기별 로그 압축. 매 분기 첫날(1·4·7·10월 1일 09:00) 스케줄러가 실행한다(L-103).
# - state/logs 의 audit.jsonl·briefing.log 에서 90일 지난 줄을 분기별 gz 로 옮긴다(archive/). 지우지 않고 압축 보관.
# - 끝나면 로그 총용량(압축 전후·보관 폴더)을 텔레그램으로 보고한다.
# 사용법: rotate-logs.sh [--dry-run]
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
ROOT="${ASSISTANT_HOME:-$HOME/assistant}"; LOGDIR="${ROTATE_LOGDIR:-$ROOT/state/logs}"; ARC="$LOGDIR/archive"
DRY=0; [ "$1" = "--dry-run" ] && DRY=1
mkdir -p "$ARC"; chmod 700 "$ARC"
sz() { du -sk "$1" 2>/dev/null | awk '{print $1}'; }
BEFORE=$(sz "$LOGDIR")
RESULT=$(DRY=$DRY LOGDIR="$LOGDIR" ARC="$ARC" python3 -I - <<'PY'
import os,re,gzip,datetime,collections
dry=os.environ['DRY']=='1'; L=os.environ['LOGDIR']; A=os.environ['ARC']
cut=(datetime.date.today()-datetime.timedelta(days=90)).isoformat()
rx=re.compile(r'(\d{4}-\d{2}-\d{2})')
out=[]
for name in ('audit.jsonl','briefing.log'):
    p=os.path.join(L,name)
    if not os.path.exists(p): continue
    keep=[];old=collections.defaultdict(list)
    for line in open(p,encoding='utf-8',errors='replace'):
        m=rx.search(line[:40]) if name=='briefing.log' else rx.search(line)
        d=m.group(1) if m else None
        if d and d<cut:
            y,mo=int(d[:4]),int(d[5:7]); old[f"{y}Q{(mo-1)//3+1}"].append(line)
        else: keep.append(line)
    n=sum(len(v) for v in old.values())
    out.append(f"{name} 압축 {n}줄 / 유지 {len(keep)}줄")
    if dry or n==0: continue
    for q,lines in old.items():
        with gzip.open(os.path.join(A,f"{name}.{q}.gz"),'at',encoding='utf-8') as g: g.writelines(lines)
    tmp=p+'.tmp'; open(tmp,'w',encoding='utf-8').writelines(keep); os.replace(tmp,p)
print(' | '.join(out) if out else '대상 없음')
PY
)
AFTER=$(sz "$LOGDIR"); ARCSZ=$(sz "$ARC")
MSG="🗜️ 로그 분기 압축 결과: ${RESULT}
총용량 ${BEFORE}KB → ${AFTER}KB (압축 보관 폴더 ${ARCSZ}KB 포함)
위치: $LOGDIR (90일 지난 줄은 archive/ 에 분기별 gz)"
print -r -- "$(date '+%F %T') [rotate] ${RESULT}, ${BEFORE}KB→${AFTER}KB" >> "$LOGDIR/briefing.log"
if [ $DRY -eq 1 ]; then print -r -- "(dry-run: 변경·전송 없음)"; print -r -- "$MSG"; exit 0; fi
[ -n "$NO_TG" ] && { print -r -- "$MSG"; exit 0; }   # 시험용: 전송 안 함
source "$ROOT/scripts/tg-lib.sh"; tg_send_text "$MSG"
