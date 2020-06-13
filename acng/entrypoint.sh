#! /usr/bin/env bash
set -euxo pipefail

exec start-stop-daemon --start --exec $(which cron) -- \
	cron -n -L "${LOGLEVEL:-4}"

/sbin/entrypoint.sh

