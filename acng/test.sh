#! /usr/bin/env bash
set -euxo pipefail

H=0
while getopts "H" arg ; do
  case $arg in
    H) # indicates tests which cannot be run on the host
      H=1
      ;;
    -)
      break
      ;;
    *) # invalid option
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))
(( ! $# ))

#NCF="${NCF:--N}"
NCF="${NCF:--w 3}"

[[ -s /etc/apt-fast.conf ]]

(( "$H" )) || exit 0

nc $NCF localhost 2413 < /dev/null |
read -t 0

