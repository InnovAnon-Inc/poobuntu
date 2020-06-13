#! /usr/bin/env bash
set -euo pipefail

D=0
while getopts "d" arg ; do
  case $arg in
    d)
      D=1
      ;;
    *) # invalid option
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))
(( ! $# ))

if (( ! "$D" )) ; then
  T="$(mktemp)"
  trap "rm -rf $T" 0
  cat > "$T"
  lrzip -z -U -q --outfile - -- "$T"
else
  lrunzip -f -q --outfile -
fi

