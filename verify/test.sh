#! /usr/bin/env bash
set -euxo pipefail

#NCF="${NCF:--N}"
NCF="${NCF:--w 3}"

random_file () {
  (( $# == 1 )) || return $?
  head -c $((RANDOM % 2048)) < /dev/urandom > "$1"
  return $?
}
T="$(mktemp)"
trap "rm -f $T" 0
random_file "$T"

test_helper () {
  (( $# >= 2 )) || return $?
  local p="$1"
  shift
  { echo "$p" ;
    eval "test$p" ;
  } |
  "$@"
  return $?
}

test0 () {
  (( ! $# )) || return $?
  gpg --sign --output - -- "$T"
  return $?
}

random_dir () {
  (( $# == 1 )) || return $?
  local k
  for ((k=$((RANDOM % 5 + 1)); k; k--)) ; do
    random_file "$(mktemp -p "$1")" || return $?
  done
  return $?
}
random_tree () {
  if (( $# == 1 )) ; then
    local depth=0
  elif (( $# == 2 )) ; then
    local depth="$(($2 + 1))"
  else return 1
  fi
  random_dir "$1" || return $?

  (( "$depth" < 3 )) || return 0

  local k
  for ((k=$((RANDOM % 3 + 1)); k; k--)) ; do
    random_tree "$(mktemp -p "$1" -d)" "$depth" || return $?
  done
  return $?
}
D="$(mktemp -d)"
trap "rm -fr $T $D" 0
mkdir -v "$D/input"
set +x
random_tree "$D/input"
set -x

test1 () {
  (( ! $# )) || return $?
  ???
  return $?
}

test2 () {
  (( ! $# )) || return $?
  cp -a "$D/input" "$D/tmp" || return $?
  find "$D/tmp" \! -type d -execdir gpg --detach-sign {} + || return $?
  tar -O - -cf "$D/tmp"
  return $?
}

ps=( ./verify.sh )
(( ! "$H" )) ||
ps+=( "nc $NCF localhost 27550" )
for k in 0 2 ; do
  for p in "${ps[@]}" ; do
    test_helper "$k" $p
  done
done

