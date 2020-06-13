#! /usr/bin/env bash
set -euo pipefail

H=0 # no help
L=0 # client mode
Q=1 # quiet
X=0 # no trace
while getopts "hlqx" arg ; do
  case $arg in
    l) # "L" is for "server"
      L=1
      ;;
    h)
      H=1
      ;;
    q) # disable quiet mode
      Q=0
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

(( ! "$X" )) || set -x # enable tracing

if (( "$H" )) ; then # display help; exit 1
  cat 1>&2 << EOF
Usage: $0 [-h] [-l] [-q] [-x]
you pipe data to it
EOF
  exit 1
fi

if (( "$Q" )) ; then
  Q=-q
  S=-s
else
  Q=
  S=
fi

if   ((  $#  )) ; then # pipe to an arbitrary command
  args=("$@")
elif (( "$L" )) ; then # server mode
  args=(nc -l localhost 27700)
else                   # client mode
  args=(nc -N localhost 27700)
fi

GPG_FLAGS="${GPG_FLAGS:---compress-level=0 --bzip2-compress-level=0}"
GPG_FLAGS="${GPG_FLAGS} --batch --no-greeting --no-tty"
[[ -z "$Q" ]] ||
GPG_FLAGS="${GPG_FLAGS} --quiet"

RETRIES=5 # number of retries for download+stego

[[ "$PEXELS_AUTH" ]]

compress () {
 T="$(mktemp)"                                                      || return $?
 trap "rm -f $T" 0                                                  || return $?
 cat > "$T"                                                         || return $?
 [[ -s "$T" ]]                                                      || return $?
 lrzip -U -z $Q -f --outfile - -- "$T"
 return $?
}
decompress () {
  lrunzip $Q -f
  return $?
}
encrypt () {
  gpg $GPG_FLAGS --encrypt \
    --recipient InnovAnon-Inc@protonmail.com - 2> /dev/null
  return $?
}
decrypt () {
  gpg $GPG_FLAGS --decrypt - 2> /dev/null
  return $?
}
stego () {
  T="$(mktemp -d)"                                                  || return $?
  trap "rm -fr $T" 0                                                || return $?
  D="$T/d"                                                          || return $?
  I="$T/i.jpg"                                                      || return $?
  O="$T/o.jpg"                                                      || return $?
  cat > "$D"                                                        || return $?
  [[ -s "$D" ]]                                                     || return $?
  R=0                                                               || return $?
  curl $S -H \
    "Authorization: $PEXELS_AUTH" \
    https://api.pexels.com/v1/search?query=cats |
  jq -r '.photos[].src.original' |
  grep -i '\.jpe\?g$' |
  sort -R |
  #tee /dev/stderr |
  #head -n 1 |
  #xargs -r curl $S -L -o "$I"
  #outguess -p 100 -d "$D" "$I" "$O"
  while read -r line ; do
    ((R++))                                                         || :
    (( $R <= $RETRIES ))                                            || return $?
    #echo "$line" 1>&2 >& /dev/null
    curl $S -L -o "$I" "$line"                                      || return $?
    outguess -p 100 -d "$D" "$I" "$O" >& /dev/null                  || continue
    break
  done                                                              || return $?
  [[ -s "$O" ]]                                                     || return $?
  cat "$O"
  return $?
}
unsteg () {
  T="$(mktemp -d)"                                                  || return $?
  trap "rm -fr $T" 0                                                || return $?
  I="$T/i.jpg"                                                      || return $?
  O="$T/o.jpg"                                                      || return $?
  cat > "$I"                                                        || return $?
  [[ -s "$I" ]]                                                     || return $?
  outguess -r "$I" "$O" >& /dev/null                                || return $?
  [[ -s "$O" ]]                                                     || return $?
  cat "$O"
  return $?
}

SEND='compress | encrypt | stego'
RECV='unsteg   | decrypt | decompress'
if (( ! "$L" )) ; then # client mode
  eval $SEND | "$@" | eval $RECV
else
  eval $RECV | "$@" | eval $SEND
  #T="$(mktemp -d)"
  #trap "rm -fr $T" 0
  #T="$T/f"
  #mkfifo "$T"
  ##eval $RECV < "$T" | "$@" | eval $SEND > "$T"
  ##eval $SEND < "$T" | "$@" | eval $RECV > "$T"
  ##eval $RECV < "$T" | eval $SEND | "$@" > "$T"
fi

