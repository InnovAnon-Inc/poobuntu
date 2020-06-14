#! /usr/bin/env bash
set -euxo pipefail

#start-stop-daemon --start --exec $(which cron) -- \
#	cron -n -L "${LOGLEVEL:-4}"
#cron -n -L "${LOGLEVEL:-4}"

start-stop-daemon --start --exec /etc/init.d/inetutils-inetd -- start

/tts/tts.sh << EOF
TTS online

EOF

