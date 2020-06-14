#! /usr/bin/env bash
set -euxo pipefail

T="$(mktemp)"
trap "rm -rf $T" 0

args=(
  # disable everything
  '-C -E -K'
  # compression only
     '-E -K'
  # no kitties
        '-K'
  # encryption only
  '-C    -K'
  # kitties only
  '-C -E'
  # no compression
  '-C'
  # no encryption
  '-E'
  # enable everything
  '' )
tests=(
  # disable server send, client recv
  -t
  # enable full pipeline
  ''
)

variant0 () {
  (( ! $# )) || return $?
  ./stego.sh $k $p \
    cat < "$0" > "$T"
  return $?
}
variant1 () {
  (( ! $# )) || return $?
  ./stego.sh   $k $p    \
    ./stego.sh $k $p -l \
      cat < "$0" > "$T"
  return $?
}
variant2 () {
  (( ! $# )) || return $?
  ./stego.sh $k $p -l &
  ./stego.sh $k $p < "$0" > "$T" || return $?
  wait -n
  return $?
}

variant_helper () {
  (( $# == 1 )) || return $?
  "$1" || return $?
  diff -q "$0" "$1"
  return $?
}

for c in {0..2} ; do
for p in "${args[@]}" ; do
for k in "${tests[@]}" ; do
  variant_helper "variant$c" || exit $?
done
done
done

(( "$H" )) || exit 0

variant3 () {
  (( ! $# )) || return $?
  ./stego.sh $k $p \
    nc localhost 27700 < "$0" > "$T"
  return $?
}

for c in 3 ; do
for p in "${args[@]}" ; do
for k in "${tests[@]}" ; do
  variant_helper "variant$c" || exit $?
done
done
done

