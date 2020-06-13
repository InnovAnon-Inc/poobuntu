#! /usr/bin/env bash
set -euxo pipefail

DENV="`command -v delete.env`" || :
if [[ "$DENV" ]] ; then
. "$DENV"
else
  D=0
fi
(( ! $# ))

if (( "$D" )) ; then
  rm -fv /opt/mirrors-*.txt \
         "$0"
  exit $?
fi

#NETSELECT="${NETSELECT:-127.0.0.1}"
#NETSELECT="${NETSELECT:-netselect}"
# TODO don't hardcode IPs/domains
NETSELECT="${NETSELECT:-lmaddox.chickenkiller.com}"
#NETSELECT="${NETSELECT:-$NETSELECT_HOST}"

mirrors_ubuntu () {
  cat
  return $?
}
mirrors_debian () {
  sed -n 's@.*href="\(http[^"]*\)".*@\1@pig'
  return $?
}
mirrors_kali () {
  mirrors_debian |
  grep -v maps.google.com
}
mirrors_savannah () {
  mirrors_debian |
  grep -v '^#'
}

mirrors () {
  (( $# == 2 )) || return $?
  [[ -f "/opt/mirrors-$1.txt" ]] ||
  touch "/opt/mirrors-$1.txt" || return $?

  curl -L "$2" |
  eval "mirrors_$1" |
  tee "/opt/mirrors-$1.tmp" || return $?

  [[ ! -s "/opt/mirrors-$1.tmp" ]] ||
  mv -v "/opt/mirrors-$1".{tmp,txt}
  return $?
}

fastest_mirrors () {
  (( $# == 2 )) || return $?
  [[ -f "/opt/mirrors-$1.txt" ]] &&
  [[ -s "/opt/mirrors-$1.txt" ]] ||
  mirrors "$@" || return $?

  [[ -f "/opt/fastest-mirrors-$1.txt" ]] ||
  touch "/opt/fastest-mirrors-$1.txt" || return $?

  nc -N -q 0 "$NETSELECT" 27400 < "/opt/mirrors-$1.txt" |
  tee "/opt/fastest-mirrors-$1.tmp" || return $? # "logging"

  [[ -s "/opt/fastest-mirrors-$1.tmp" ]] ||
  continue
  mv -v "/opt/fastest-mirrors-$1".{tmp,txt}
  return $?
}

fastest_mirrors ubuntu   http://mirrors.ubuntu.com/mirrors.txt
fastest_mirrors debian   https://www.debian.org/mirror/list
#fastest_mirrors kali     https://http.kali.org/README.mirrorlist
#fastest_mirrors savannah https://download.savannah.nongnu.org/mirmon/gnu/

#curl -L http://mirrors.ubuntu.com/mirrors.txt  |
#nc -N -q 0 "$NETSELECT" 27400                  |
#tee /opt/mirrors-ubuntu.txt.tmp
#curl -L
#|
#nc -N -q 0 "$NETSELECT" 27400                  |
#tee /opt/mirrors-debian.txt.tmp
#
tee /etc/apt-fast.conf << EOF
_APTMGR=apt
DOWNLOADBEFORE=true
MIRRORS=( $(/acng/netselect.awk /opt/mirrors-ubuntu.txt) $(/acng/netselect.awk /opt/mirrors-debian.txt) )
EOF

#rm -v /opt/mirrors-{debian,ubuntu}.txt

apt-fast update
apt-fast full-upgrade

