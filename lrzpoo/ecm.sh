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
  lrzip -n -U -q -f --outfile - -- "$O" |
  7z c -bd -si -so -y -ssw -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on
else
  7z x -bd -si -so -y |
  lrunzip -f -q --outfile "$I" 2> /dev/null || :
  ecm-uncompress "$I" "$O" > /dev/null
  cat "$O"
fi

