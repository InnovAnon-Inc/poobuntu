#! /usr/bin/env bash
set -euo pipefail

D=0
X=0
while getopts "dx" arg ; do
  case $arg in
    d)
      D=1
      ;;
    x)
      X=1
      ;;
    *) # invalid option
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))
(( ! $# ))

(( ! "$X" )) ||
set -x

I="$(mktemp)"
O="$(mktemp)"
trap "rm -rf $I $O" 0

if (( ! "$D" )) ; then
  cat > "$I"
  ecm-compress   "$I" "$O" > /dev/null
  /tlrz/tlrz.sh < "$I"
else
  /tlrz/tlrz.sh -d > "$I"
  ecm-uncompress "$I" "$O" > /dev/null
  cat "$O"
fi

