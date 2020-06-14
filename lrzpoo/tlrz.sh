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

if (( ! "$D" )) ; then
  T="$(mktemp)"
  trap "rm -rf $T" 0
  cat > "$T"
  lrzip -z -U -q -f --outfile - -- "$T"
else
  lrunzip -f -q --outfile -
fi

