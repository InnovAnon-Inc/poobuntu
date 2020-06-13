#! /usr/bin/env bash
set -euxo pipefail

for k in redirect.sh upgrade.sh install.sh ; do
  [[ ! `command -v "$k"` ]] ||
  "$k" -d                   || exit $?
done
for k in netselect.awk delete.env ; do
  [[ ! `command -v "$k"` ]] ||
  rm -v "`command -v "$k"`" || exit $?
done
rm -rf /common /poobuntu /acng /netselect
#rm -v /etc/apt/apt.conf.d/02minimal /etc/apt/apt.conf.d/02compress
rm -v "$0"

