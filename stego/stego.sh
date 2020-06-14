#! /usr/bin/env bash
set -euo pipefail # quit on error, fail on unset vars, any subcommand can cause a pipe to fail

C=1 # enable compression
E=1 # enable encryption
K=1 # enable stego
H=0 # no help
L=0 # client mode
X=0 # no trace
T=0 # no test
V=0 # tacit
while getopts "ltCEKhvx-" arg ; do
  case $arg in
    l) # "L" is for "server"... as in, "netcat"
      L=1
      ;;
    t) # enable test mode
      T=1
      ;;
    C)
      C=0
      ;;
    E)
      E=0
      ;;
    K)
      K=0
      ;;
    h) # standard help functionality
      H=1
      ;;
    v) # enable verbosity
      V=1
      ;;
    x) # bash tracing
      X=1
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

(( ! "$X" )) || set -x # enable tracing

log () {
  "$@" 1>&2
  return $?
}

if (( "$H" )) ; then # display help; exit 1
  log cat << EOF
Usage: $0 [-l] [-C] [-E] [-K] [-t] [-h] [-v] [-x] [--]
you pipe data to it

Optional Parameters:
  -l (L)isten mode
     Inverts filters
     Intended to be run as a server:
     - standalone (uses netcat by default)
         PEXELS_AUTH=<token> $0 -l
     - subserver  (e.g., inetd)
         PEXELS_AUTH=<token> $0 -l --

  Protocol:
    -C (C)ompression; disable it
    -E (E)ncryption;  disable it
    -K (K)itties;     disable stego layer
    -t (T)est: ACHTUNG! server replies in plaintext

  Standard Options:
  -h (H)elp
  -v (V)erbose mode
  -x trace (set -x)
  -- stop optional parameter processing

Positional Arguments: none

Input:  flat file

Output: flat file

EOF
  exit 1
fi

if (( ! "$V" )) ; then
  Q=-q
  S=-s
  TT=
else
  Q=
  S=
  TT=-t
fi

#NCF="${NCF:--N}"
NCF="${NCF:--w 3}"

# TODO KITTY_HOST KITTY_PORT
if   ((  $#  )) ; then # pipe to an arbitrary command
  args=("$@")
elif (( "$L" )) ; then # server mode
  args=( nc $NCF -l localhost 27700 )
else                   # client mode
  args=( nc $NCF    localhost 27700 )
fi

GPG_FLAGS="${GPG_FLAGS:-}"
if (( "$C" )) ; then
  GPG_FLAGS="${GPG_FLAGS} --compress-level=0 --bzip2-compress-level=0}" # we do it "better"
else
  GPG_FLAGS="${GPG_FLAGS} --compress-level=9 --bzip2-compress-level=9}" # we do it "better"
fi
GPG_FLAGS="${GPG_FLAGS} --batch --no-greeting --no-tty" # srsly tho, stfu
[[ -z "$Q" ]] ||
GPG_FLAGS="${GPG_FLAGS} --quiet"

RETRIES="${RETRIES:-10}" # number of retries for download+stego

[[ "$PEXELS_AUTH" ]]

compress () {
  (( ! $# ))                                                        || return $?
  local TTT="$(mktemp)"                                             || return $?
  trap "rm -f $TTT" 0                                               || return $?
  cat > "$TTT"                                                      || return $?
  [[ -s "$TTT" ]]                                                   || return $?
  lrzip -U -z $Q -f --outfile - -- "$TTT"
  return $?
}
decompress () {
  (( ! $# ))                                                        || return $?
  lrunzip $Q -f
  return $?
}
encrypt () {
  (( ! $# ))                                                        || return $?
  gpg $GPG_FLAGS --encrypt \
    --recipient InnovAnon-Inc@protonmail.com -
  return $?
}
decrypt () {
  (( ! $# ))                                                        || return $?
  gpg $GPG_FLAGS --decrypt -
  return $?
}
stego () {
  (( ! $# ))                                                        || return $?
  local TTT="$(mktemp -d)"                                          || return $?
  trap "rm -fr $TTT" 0                                              || return $?
  local D="$TTT/d"                                                  || return $?
  local I="$TTT/i.jpg"                                              || return $?
  local O="$TTT/o.jpg"                                              || return $?
  cat > "$D"                                                        || return $?
  [[ -s "$D" ]]                                                     || return $?
  local R=0                                                         || return $?
  # TODO parameterize search query
  # TODO handle pagination
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
  # TODO buffer some images
  while read -r line ; do
    ((R++))                                                         || :
    (( $R <= $RETRIES ))                                            || return $?
    #echo "$line" 1>&2 >& /dev/null
    curl $S -L -o "$I" "$line"                                      || return $?
    # TODO what is a reasonable value for x ?
    log outguess $TT -x 23 -p 100 -d "$D" "$I" "$O"                 || continue
    break
  done                                                              || return $?
  [[ -s "$O" ]]                                                     || return $?
  # TODO "scrub" input by doing simon algo
  # to create unique images (helps with stego)
  cat "$O"
  return $?
}
unsteg () {
  (( ! $# ))                                                        || return $?
  local TTT="$(mktemp -d)"                                          || return $?
  trap "rm -fr $TTT" 0                                              || return $?
  local I="$TTT/i.jpg"                                              || return $?
  local O="$TTT/o.jpg"                                              || return $?
  cat > "$I"                                                        || return $?
  [[ -s "$I" ]]                                                     || return $?
  log outguess $TT -r "$I" "$O"                                     || return $?
  [[ -s "$O" ]]                                                     || return $?
  cat "$O"
  return $?
}

if (( "$C" )) ; then
  CLAYER=compress
  SLAYER=decompress
else
  CLAYER=cat
  SLAYER=cat
fi
SEND="${CLAYER}"
RECV="${SLAYER}"

if (( "$E" )) ; then
  CLAYER=encrypt
  SLAYER=decrypt
else
  CLAYER=cat
  SLAYER=cat
fi
SEND="${SEND}   | ${CLAYER}"
RECV="${SLAYER} | ${SEND}"

if (( "$K" )) ; then
  CLAYER=stego
  SLAYER=unsteg
else
  CLAYER=cat
  SLAYER=cat
fi
SEND="${SEND}   | ${CLAYER}"
RECV="${SLAYER} | ${SEND}"

#SEND='compress | encrypt | stego'
#RECV='unsteg   | decrypt | decompress'

if (( ! "$L" )) ; then # client mode
  (( ! "$T" )) ||
  RECV=cat
  # TODO append exif scrubbing to $SEND
  (( ! "$V" )) ||
  log echo "$SEND |" "${args[@]}" "|& $RECV"
      eval  $SEND |  "${args[@]}"  |& eval $RECV
else
  (( ! "$T" )) ||
  SEND=cat
  (( ! "$V" )) ||
  log echo "$RECV |" "${args[@]}" "|& $SEND"
      eval  $RECV |  "${args[@]}"  |& eval $SEND
  #T="$(mktemp -d)"
  #trap "rm -fr $T" 0
  #T="$T/f"
  #mkfifo "$T"
  ##eval $RECV < "$T" | "$@" | eval $SEND > "$T"
  ##eval $SEND < "$T" | "$@" | eval $RECV > "$T"
  ##eval $RECV < "$T" | eval $SEND | "$@" > "$T"
fi

