#! /usr/bin/env bash
set -euo pipefail

# util func
log () {
  $* 1>&2
  return $?
}

# set defaults
Q="${Q:-1}" # default enable
V="${V:-0}" # default disable
X="${X:-0}" # default disable
# TODO (T)est  - verify compression
# TODO (C)heck - verify decompression

# options
while getopts "ehqvx" arg ; do
  case $arg in
    q) # quiet
      Q=0 # disable
      ;;
    v) # verbose
      V=1 # enable
      ;;
    x) # trace
      X=1 # enable
      ;;
    e) # environment
      log env
      ;;
    h) # help
      log sed '/^#/d' << EOF
filters: gpg(dec) tar(if multi)
         lrzip(if comp) zpaq(if comp)
         gpg
         tar(if multi) gpg(enc)

usage: $0 [-e] [-h] [-q] [-v] [-x]
  -e     env: current Environment to stderr
  -h    help: usage info to stderr
  -q   quiet: (passed to subprocesses)
  -v verbose: (passed to subprocesses)
  -x   trace: set -x

stdin:
line #1> C (bool)   enable (de)Compression
line #2> X (bool)   eXtract: invert filters
line #3> M (enum)   Mode #
#line #4> R (string) Recipient (for modes 1, 2)
line  *> (remaining lines input to subprocess)

Mode 0: (echo)

Mode 1: --sign --encrypt --recipient <fingerprint>
  input:
#  - line #4> R (string) Recipient
  - (tape archive for multi-file support)
    - <client priv key>
    - <client pub  key>
    - <recip  pub  key>
    - <data>
  output: <data>[.lrz.zpaq].gpg

Mode 2: --detach-sign
  input:
#  - line #4> R (string) Recipient
  - (tape archive for multi-file support)
    - <client priv key>
    - <client pub  key>
    - <data>
  output: (tape archive if compressing; just .sig file otherwise)
  - [<data>.lrz.zpaq] (don't echo <data> if !\$C)
  - <data>[.lrz.zpaq].sig

Mode 3: --verify sig <file>...
  input: (tape archive for multi-file support)
  - <sig>
  - [.sigs/*.sig]
  - <data>
  output: (unspecified)

Mode 4: --verify     <file>...
  input:  <data>
  output: (unspecified)

EOF
      exit 1
      ;;
    *) # invalid option
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

# check usage
(( ! $# ))
[[ "$Q" ]]
[[ "$V" ]]
[[ "$X" ]]

# quiet mode
if (( "$Q" )) ; then
  Q1=-q
  Q2=q
else
  Q1=
  Q2=
fi

# verbose mode
if (( "$V" )) ; then
  V1=-v
  V2=v
else
  V1=
  V2=
fi

# tracing mode
(( ! "$X" )) ||
set -x

unset Q V X

# configurable params
GPG_CONF="${GPG_CONF:-/dev/null}"
# TODO --no-default-keyring
#GPG_FLAGS="${GPG_FLAGS:-"--quiet --batch --no-tty --no-greeting --enable-large-rsa --require-secmem --set-filename '' --for-your-eyes-only --throw-keyids"}"
GPG_FLAGS="${GPG_FLAGS:-"--quiet --batch --no-tty --no-greeting --enable-large-rsa --require-secmem --for-your-eyes-only --throw-keyids"}"
#--options "$GPG_CONF"
LEVEL="${LEVEL:-9}" # gpg compression level (if !$C)
#--owner=<root,nobody,1000>
#--group=<^^^>

# pluggable filters
# usage: filter_$ext_{c,x} <output.$ext> <input>

filter_tar_c  () { # used to archive our data
  log tar "${V2}cf"  \
    --absolute-names \
    --group=nogroup  \
    --mtime=0        \
    --no-acls        \
    --numeric-group  \
    --numeric-owner  \
    --owner=nobody   \
    --sort=name      \
    --sparse         \
    -O "$1" -- "$2"
  return $?
}
filter_tar_x  () { # used to extract user data
  log tar "${V2}xf" \
    --numeric-group \
    --numeric-owner \
    --preserve      \
    -O "$1" -- "$2"
  return $?
}
filter_lrz_c  () {
  log lrzip ${Q1} ${V1} \
    --no-compress       \
    --unlimited         \
    --outfile "$1" -- "$2"
  return $?
}
filter_lrz_x  () {
  log lrzip ${Q1} ${V1} \
    --decompress        \
    --outfile "$1" -- "$2"
  return $?
}
filter_zpaq_c () { # TODO s
  log zpaq "${Q2}${V2}nc" "$1" "$2"
  return $?
}
filter_zpaq_x () {
  log zpaq "${Q2}${V2}x" "$1" "$2"
  return $?
}
# TODO redundant
filter_gpg_c  () {
  log gpg ${Q1} ${V1} $GPG_FLAGS $GPG_OP \
    --output "$1" -- "$2"
  return $?
}
filter_gpg_x  () {
  log gpg ${Q1} ${V1} $GPG_FLAGS $GPG_OP \
    --output "$1" -- "$2" 
  return $?
}
filter_sig_c  () {
#      gpg ${Q1} ${V1} $GPG_FLAGS $GPG_OP \
#        -- "$2" >& "$1"
  log gpg ${Q1} ${V1} $GPG_FLAGS $GPG_OP \
    --output "$1" -- "$2" 
  return $?
}
filter_sig_x  () {
#      gpg ${Q1} ${V1} $GPG_FLAGS $GPG_OP \
#        -- "$2" >& "$1"
  log gpg ${Q1} ${V1} $GPG_FLAGS $GPG_OP \
    --output "$1" -- "$2" 
  return $?
}

# apply filters
filter_all () {
  (( $# >= 3 ))                                                     || return $?
  [[ "$1" ]]                                                        || return $?
  [[ "$2" ]]                                                        || return $?
   f="$2"                                                           || return $?
  FF="$1"                                                           || return $?
  shift 2                                                           || return $?
  for ext in "$@" ; do
              F=".$ext"                                             || return $?
    eval filter="filter_$(printf -- %s_%s "$ext" "$c")"             || return $?
    "$filter" "$F" "$f"                                             || return $?
    log rm  ${V1}   -- "$f"                                         || return $?
    f="$F"                                                          || return $?
  done                                                              || return $?
  #eval filter="filter_$(printf %s_%s -- "$ext" "$c")" || return $?
  ##eval filter="filter_$ext_$c"    || return $?
  #"$filter" "$FF" "$f"            || return $?
  #rm "${V1}"      "$f"            || return $?
  log mv  ${V1}    -- "$f" "$FF"                                    || return $?
  unset f F FF
  return $? # F
}

# util func
reverse_array () {
  (( $# == 1 ))                                                     || return $?
  [[ "$1" ]]                                                        || return $?
  array="$1"                                                        || return $?
  #eval n="\${#$array[@]}"                    || return $?
  eval n="$(printf -- '${#%s[@]}' "$array")"                        || return $?
  n=$((n / 2))                                                      || return $?
  for ((i=0; i < n; i++)) ; do
                          j=$((n - i))                              || return $?
    #eval "\${$array[\$i]} = \${$array[\$j]}" || return $?
    #eval "$(printf -- '${%s[%s]}=${%s[%s]}' \
    #        "$array" "$i" "$array" "$j")"                           || return $?
    eval "$(printf -- '%s[%s]=${%s[%s]}' \
            "$array" "$i" "$array" "$j")"                           || return $?
                        ((j++))                                     || return $?
  done                                                              || return $?
  unset array n i j
  return $?
}

# helper function
function import_keys {
  (( $# ))                                           || return $? # sanity check
  for key in $@ ; do
    log gpg ${Q1} ${V1} $GPG_FLAGS --import "$key"                  || return $?
    log rm        ${V1}                     -- "$key"               || return $?
  done                                                              || return $?
  unset key
  return $?
}

# echo
input_0  () {
  :
}
output_0 () {
  :
}

# move .data into place (.input), verify no unexpected cruft
input_helper () {
  log mv     ${V1}  -- .input/.data .tmp                            || return $?
  log rmdir  ${V1}  -- .input                                       || return $?
  log mv     ${V1}  -- .tmp         .input
  return $?
}

# <client priv key>
# <client pub  key>
# <recip  pub  key>
# <data>
input_1  () { # --sign --encrypt --recipient
  # TODO is the pub.key necessary?
  import_keys .input/{priv,pub,recipient}.key                       || return $?
  input_helper                                                      || return $?

  [[ "$recipient" ]]                                                || return $?
  GPG_OP="$(printf -- %s --sign --encrypt \
	  --hidden-recipient "$recipient")"                         || return $?
  #GPG_OP='--sign --encrypt' || return $?
}
# <data>[.lrz.zpaq].gpg
output_1 () {
  unset GPG_OP
  return $?
}

# <client priv key>
# <client pub  key>
# <data>
input_2  () { # --detach-sign
  import_keys .input/{priv,pub}.key
  return $?
  #GPG_OP="--detach-sign"            || return $?
}
# [<data>.lrz.zpaq] (don't echo <data> if !$C)
# <data>[.lrz.zpaq].sig
output_2 () {
  log gpg  ${V1}   ${Q1}  $GPG_FLAGS --detach-sign .output          || return $?
  [[ -f ".output.sig" ]]                             || return $? # sanity check
  if (( "$C" )) ; then # encryption enabled
    log mkdir  ${V1}  --                .tmp                        || return $?
    log mv     ${V1}  -- .output{,.sig} .tmp/                       || return $?
    cd                           .tmp                               || return $?
    filter_tar_c     ../.output     .output{,.sig}                  || return $?
    cd                           ..                                 || return $?
    log rm     ${V1}  --                .tmp/.output{,.sig}         || return $?
    log rmdir  ${V1}  --                .tmp
    return $?
  fi
  # encryption disabled: just return siggy to client
  log mv ${V1} -- .output{.sig,}
  return $?
}

# <sig>
# <data>
input_3  () { # --verify sig <file>...
  if [[ -d .input.sig ]] ; then
    import_keys .input/.sig/*.key                                   || return $?
    log rmdir  ${V1}    -- .sig                                     || return $?
  fi
  log mv       ${V1}    -- .input/sig.key sig.key                   || return $?
  input_helper                                                      || return $?
  GPG_OP="--verify sig.key"                                         || return $?
  log rm  ${V1}                        -- sig.key
  return $?
}
# (unspecified)
output_3 () {
  unset GPG_OP
  return $?
}

# <data>
input_4  () { # --verify <file>...
  GPG_OP="--verify"
  return $?
}
# (unspecified)
output_4 () {
  unset GPG_OP
  return $?
}

gpg_helper_enter () {
  [[ "$T" ]]                                                        || return $?
  log mkdir -m 0700 ${V1} -- "$T/.mine"                             || return $?
  # TODO --export-options export-clean export-minimal
  log gpg ${Q1} ${V1} $GPG_FLAGS \
    --export                     \
    --output "$T/.mine/pub.key"                                     || return $?
  #gpg ${Q1} ${V1} --export-secret-subkeys > "$T/.mine/priv.key"    || return $?
  log gpg ${Q1} ${V1} $GPG_FLAGS \
    --export-secret-keys         \
    --output "$T/.mine/priv.key"                                    || return $?
  log chmod ${V1} 0400 -- "$T/.mine/priv.key"                       || return $?
  GPG_FLAGS2="${GPG_FLAGS}"                                         || return $?
  GPG_FLAGS="$(printf -- '%s '     \
	     --homedir "$T/.mine"  \
	     --options "$GPG_CONF" \
	     "${GPG_FLAGS}")"                                       || return $?
  log gpg ${Q1} ${V1} $GPG_FLAGS \
    --import -- "$T/.mine/priv.key"                                 || return $?
  log gpg ${Q1} ${V1} $GPG_FLAGS \
    --import "$T/.mine/pub.key"                                     || return $?
  log rm ${V1} "$T/.mine/"{pub,priv}.key
  return $?
}
gpg_helper_leave () {
  [[ "$T" ]]                                                        || return $?
  log rm ${V1} -fr -- "$T/.mine"                                    || return $?
  GPG_FLAGS="${GPG_FLAGS2}"                                         || return $?
  unset GPG_FLAGS2
  return $?
}

input  () {
  (( $# == 1 ))                                                     || return $?
  [[ "$1" ]]                                                        || return $?
  gpg_helper_enter                                                  || return $?
  # TODO --try-all-secrets
  GPG_OP="--decrypt" \
  filter_gpg_x .input /dev/stdin                                    || return $?
  unset GPG_OP                                                      || return $?
  gpg_helper_leave                                                  || return $?
  #mv ${V1} -- .input/return.key .                || return $? # save this for later
  GPG_FLAGS="$(printf -- '%s '     \
             --homedir "$T"        \
             --options "$GPG_CONF" \
             "${GPG_FLAGS}")"      \
  eval "input_$1"                      
  return $?
}
output () {
  (( $# == 1 ))                                                     || return $?
  [[ "$1" ]]                                                        || return $?
  #[[ "$2" ]] || return $?
  #[[ "$recipient" ]]                                                || return $?
  #(( $# == 1 ))                        || return $?
  GPG_FLAGS="$(printf -- '%s '     \
             --homedir "$T"        \
             --options "$GPG_CONF" \
             "${GPG_FLAGS}")"      \
  eval "output_$1"                                                  || return $?
  gpg_helper_enter                                                  || return $?
  #import_keys return.key || return $?
  #GPG_OP='--sign --encrypt' \
  #GPG_OP="$(printf -- %s --sign --encrypt --hidden-recipient "$2")" \
# TODO (S)ecure output: allow client to add secure.gpg pub key so
#                       we can encrypt output to that recipient
#  GPG_OP="$(printf -- '%s '  \
#          --sign             \
#          --encrypt          \
#          --recipient "$2")" \
#  filter_gpg_c /dev/stdout .output                                  || return $?
cat .output || return $?
  unset GPG_OP                                                      || return $?
  gpg_helper_leave
  return $?
}
io     () {
  (( $# >= 2 ))                                                     || return $?
  [[ "$1" ]]                                                        || return $?
  #[[ "$recipient" ]] || return $?
  mode="$1"                                                         || return $?
  #client="$2"                                    || return $?
  #shift                                          || return $?
  shift 2                                                           || return $?
  filters=("$@")                                                    || return $?
  input  "$mode"                                                    || return $?
  # TODO client=??? => get client key fingerprint
  filter_all .output .input "${filters[@]}"                         || return $?
  #output "$mode" "$client"                       || return $?
  output "$mode"                                                    || return $?
  unset mode client filters 
  return $?
}

main () { # TODO encrypt read lines
  GPG_FLAGS3="$GPG_FLAGS"                                           || return $?
  # reset filters
  filters=()                                                        || return $?

  # is (extreme) compression desired?
  read C                                                            || return $?
  [[ "$C" ]]                                                        || return $?
  if (( "$C" )) ; then # enable compression
    filters+=(lrz zpaq)                                             || return $?
    CL='--compress-level 0'                                         || return $?
#    GPG_FLAGS="$(printf -- '%s ' "$GPG_FLAGS" --compress-level 0)" || return $?
  else
    CL="--compress-level       "$(printf -- %q "$LEVEL")" \
        --bzip2-compress-level "$(printf -- %q "$LEVEL")""          || return $?
#	  GPG_FLAGS="$(printf -- '%s ' "$GPG_FLAGS" --compress-level 9 --bzip2-compress-level 9)" || return $?
  fi                                                                || return $?
  GPG_FLAGS="$(printf -- '%s ' "$GPG_FLAGS" "$CL")"                 || return $?
  unset CL                                                          || return $?

  # compression/encryption mode vs. decompression/decompression mode
  read X                                                            || return $?
  [[ "$X" ]]                                                        || return $?
  if (( "$X" )) ; then # enable extraction  (reverse filters)
    reverse_array filters                                           || return $?
    c=x                                                             || return $?
  else
    c=c                                                             || return $?
  fi                                                                || return $?

  # I/O mode
  read mode                                                         || return $?
  [[ "$mode" ]]                                                     || return $?
  case "$mode" in
    0|2) # echo mode
      ;;
    1)
      filters+=(gpg)                                                || return $?
      ;;
    3|4)
      filters+=(sig)                                                || return $?
      ;;
    *) # invalid mode selection
      exit 1
      ;;
  esac                                                              || return $?

  #recipient=
  #case "$mode" in
  #  1|2) # req encryption recipient
  #    read recipient || return $?
  #    [[ "$recipient" ]] || return $?
  #    ;;
  #  *)   # no encryption
  #    ;;
  #esac

  # I/O function handles remaining I/O
  #io "$mode" "$recipient" "${filters[@]}"                     || return $?
  io "$mode" "${filters[@]}"                                        || return $?
  unset C c X mode filters                                          || return $?
  #unset recipient || return $?
  GPG_FLAGS="$GPG_FLAGS3"                                           || return $?
  unset GPG_FLAGS2                                                  || return $?
}

# TODO maybe add a new user to do all this

log umask 0007                   # TODO
T="$(mktemp  ${Q1}  -d)"               # temp working dir
T="$(readlink -f "$T")"                # use abs path for gpg home dir
trap "log popd ; log rm  ${V1}  -fr -- "$T"" 0 # clean up on exit
log chmod ${V1} 0700 -- "$T"
log cd    "$T"                             # prevent echoing start dir
log pushd "$T"                             # set PWD

main                                   # do the thing

