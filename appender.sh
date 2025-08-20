#!/bin/sh

TEXT=$1
DATE=$(date +"%Y\-%m\-%d %H:%M:%S")

curl -s "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d chat_id="$TELEGRAM_CHAT_ID" -d parse_mode="MarkdownV2" -d text=$'*'"$TEXT"$'*'$'\n\n'"$DATE" >> /dev/null