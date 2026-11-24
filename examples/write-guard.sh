#!/bin/zsh
# 쓰기 래퍼 패턴(L-100): 일정·알림 같은 항목을 만들기 전에 항상 중복을 검사한다. 지시문이 아니라 쓰기 경로에 넣는다.
#  사용법: write-guard.sh "제목" YYYY-MM-DD [HH:MM]
#  종료 코드: 0=생성함, 3=중복이라 만들지 않음, 그 외=오류. 조회가 실패하면 막지 않고 경고만 한다(정상 작업 방해 금지).
# 판정: 같은 날 + 제목 핵심어 공유. 시각만 같은 별개 항목은 막지 않는다. 사용자가 명시적으로 원하면 ALLOW_DUP=1.
title="$1"; day="$2"
existing_titles() {   # 같은 날($1)의 기존 항목 제목을 줄마다 출력. 실제 구현은 캘린더·알림 조회 명령으로 바꾼다.
  # 데모: EXISTING_FILE 에 한 줄에 하나씩 적어 두면 그것을 기존 항목으로 본다. 조회 불가면 1을 반환.
  [ -n "$EXISTING_FILE" ] && [ -r "$EXISTING_FILE" ] && { cat "$EXISTING_FILE"; return 0; }
  return 1
}
keywords() { print -r -- "$1" | tr -s ' ,/()[]' '\n' | awk 'length($0)>=2'; }
dup=0
if [ -z "$ALLOW_DUP" ]; then
  if existing=$(existing_titles "$day"); then
    for k in ${(f)"$(keywords "$title")"}; do
      print -r -- "$existing" | grep -qiF -- "$k" && { dup=1; break; }
    done
  else
    print -u2 "경고: 기존 항목 조회 실패 — 중복 검사 없이 진행"
  fi
fi
[ $dup -eq 1 ] && { print "skipped(duplicate)"; exit 3; }
# 여기서 실제 생성 명령을 호출(캘린더·알림 API 등). 생성물에는 "비서가 만들었다"는 표식을 붙여 구분·되돌리기 쉽게 한다.
print "created: [Assistant] $title $day $3"
