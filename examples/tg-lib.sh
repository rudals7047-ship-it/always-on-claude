#!/bin/zsh
# 텔레그램 Bot API로 텍스트 전송. 토큰은 코드·로그·인자에 남기지 않고 권한 600 파일에서만 읽는다.
# 준비: BotFather로 봇을 만들고, 토큰 한 줄을 $TG_TOKEN_FILE(권한 600)에, 내 chat id를 $TG_CHAT_ID_FILE에 저장.
TG_TOKEN_FILE="${TG_TOKEN_FILE:-$HOME/.assistant/tg-token}"
TG_CHAT_ID_FILE="${TG_CHAT_ID_FILE:-$HOME/.assistant/tg-chat-id}"

tg_send_text() {   # $1=본문. 성공 0, 실패 1. TG_SILENT=1 이면 알림음 없이 전송.
  local token chat
  token=$(<"$TG_TOKEN_FILE") 2>/dev/null; chat=$(<"$TG_CHAT_ID_FILE") 2>/dev/null
  [[ -n "$token" && -n "$chat" ]] || return 1
  # 토큰이 명령행(ps)에 보이지 않도록 설정은 표준 입력(curl -K -)으로 넘긴다.
  print -r -- "url = \"https://api.telegram.org/bot${token}/sendMessage\"" | \
    curl -s --max-time 20 -K - \
      --data-urlencode "chat_id=${chat}" \
      --data-urlencode "text=$1" \
      --data-urlencode "disable_notification=$([[ -n "$TG_SILENT" ]] && print true || print false)" \
      -o /dev/null -w '%{http_code}' | grep -q '^200$'
}
