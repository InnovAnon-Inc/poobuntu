#! /usr/bin/env bash
set -euo pipefail

K=0
X=0
while getopts "kx" arg ; do
  case $arg in
    k)
      K=1
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

(( ! "$X" )) || set -x

T="$(mktemp)"
trap "rm -f $T" 0

if [[ -z "${TESTFILE:-}" ]] ; then
  TESTFILE="$(mktemp)"
  trap "rm -f $T $TESTFILE" 0
  head -c "$((RANDOM % 2047 + 1))" \
	  < /dev/urandom \
	  > "$TESTFILE"
fi

#NCF="${NCF:--q 0}"
NCF="${NCF:--w 3}"

test1 () { # unit test
  ./lrzdct.sh < "$TESTFILE" |
  ./lrzdct.sh -d > "$T"
  return $?
}

test2 () { # test client
  nc $NCF localhost 27600 < "$TESTFILE" |
  ./lrzdct.sh -d > "$T"
  return $?
}

test3 () { # test server
  ./lrzdct.sh < "$TESTFILE" |
  nc $NCF localhost 27601 |
  PORT=27601 netkitty \
    ./lrzdct.sh -d > "$T"
  return $?
}

test4 () { # full test
  nc $NCF localhost 27600 < "$TESTFILE" |
  PORT=27601 netkitty \
    ./lrzdct.sh -d > "$T"
  return $?
}

test_helper () {
  (( $# )) || return $?
  "$@" || return $?
  diff -q "$TESTFILE" "$T"
  return $?
}

run_tests () {
  F=0
  ((  $#  )) || return $?
  (( "$1" )) || return $?
  local n="$1" || return $?
  eval local range=( {1.."$n"} ) || return $?
  shift
  for k in "${range[@]}" ; do
    test_helper "test$k" "$@" ;
    local p="$?"
    (( "$p" )) || continue
    (( F++ )) || :
    (( "$K" )) || return "$p"
  done
  return "$F"
}

if (( "$H" )) ; then
  n=4
else
  n=1
fi
run_tests "$n"

