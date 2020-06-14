#! /usr/bin/env bash
set -euxo pipefail

export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

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

random_file () {
  (( $# == 1 )) || return $?
  head -c $((RANDOM % 2048)) < /dev/urandom > "$1"
  return $?
}
T="$(mktemp)"
trap "rm -f $T" 0
random_file "$T"

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
set +x
random_tree "$D"
set -x




test_helper () {
  (( $# >= 3 )) || return $?
  local testn="$1"
  local proto="$2"
  shift 2
  { cat << EOF
$cksum
$proto
EOF
  #(( "$?" )) || return $?
  "$testn" || return $?
  } |
  "$@"
  local status="$?"
  (( "$proto" % 2 == 0 )) ||
  echo completed "$testn" '|' "$@"
  return $status
}

TT="$(mktemp)"
trap "rm -rf $D $T $TT" 0


test_helper_chk () {
  (( $# == 3 )) || return $?
  local t="$1"
  local u="$(( t + 1 ))"
  test_helper "test$t" "$t" "$2" | tee "$TT" || return $?
  test_helper "test$u" "$u" "$3"
  return $?
}

test_helper_chk2 () {
  (( $# == 2 )) || return $?
  for k in 0 2 4 ; do
    test_helper_chk "$k" "$@" || return $?
  done
  return $?
}

nettest () {
  (( ! $# )) || return $?
  netcat $NCF localhost 27500
  return $?
}

test0 () {
  (( ! $# )) || return $?
  cat "$T"
  return $?
}
test1 () {
  (( ! $# )) || return $?
  cat "$TT" || return $?
  cat "$T"
  return $?
}
test2 () {
  (( ! $# )) || return $?
  tar -cf - "$D"
  return $?
}
test3 () {
  (( ! $# )) || return $?
  # TODO don't clobber files
  mv -v "$TT" "$D/${cksum}s" || return $?
  tar -cf - "$D"
  return $?
}
test4 () {
  (( ! $# )) || return $?
  tar -cf - "$D"
  return $?
}
test5 () {
  (( ! $# )) || return $?
  rm -v "$D/${cksum}s" || return $?
  find . "$D" -type f |
    xargs -I % bash -c "(printf -- '%q ' \
                         $cksum % '>' %.$cksum)"
  return $?
}


for cksum in md5sum sha{1,224,256,384,512}sum ; do
  test_helper_chk2 ./cksum.sh ./cksum.sh || exit $?
done

(( "$H" )) || exit 0

for TEST in \
  'test_helper_chk2 ./cksum.sh nettest'    \
  'test_helper_chk2 nettest    ./cksum.sh' \
  'test_helper_chk2 nettest    nettest'
do
  for cksum in md5sum sha{1,224,256,384,512}sum ; do
    $TEST || exit $?
  done
done


exit 0









test_helper1 () {
  
}





test0 "$cksum" 

$cksum

for cksum in md5sum sha{1,224,256,384,512}sum ; do
  rm -f "${cksum}s"
  { echo $cksum ;
    echo 0      ;
    cat "$0"    ;
  } |
  netcat $NCF localhost 27500 |
  tee ${cksum}s

  { echo $cksum ;
    echo 1      ;
    cat ${cksum}s ;
    cat "$0"    ;
  } |
  netcat $NCF localhost 27500
  rm ${cksum}s

  { echo $cksum ;
    echo 2      ;
    tar cf - .  ;
  } |
  netcat $NCF localhost 27500 |
  tee ${cksum}s

  { echo $cksum ;
    echo 3      ;
    tar cf - .  ;
  } |
  netcat $NCF localhost 27500
  rm ${cksum}s
done

