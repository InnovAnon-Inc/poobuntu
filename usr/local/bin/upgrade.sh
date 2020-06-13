#! /usr/bin/env bash
set -euxo pipefail

. `command -v delete.env`
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
curl -L http://mirrors.ubuntu.com/mirrors.txt  |
nc -N -q 0 "$NETSELECT" 27400                  |
tee /opt/mirrors-ubuntu.txt
curl -L https://www.debian.org/mirror/list     |
nc -N -q 0 "$NETSELECT" 27400                  |
tee /opt/mirrors-debian.txt

{ echo _APTMGR=apt         ;
  echo DOWNLOADBEFORE=true ;
  echo MIRRORS=(           \
    "$(/poobuntu/netselect.awk /opt/mirrors-ubuntu.txt)" \
    "$(/poobuntu/netselect.awk /opt/mirrors-debian.txt)" \
  )                        ;
  echo                     ;
} |
tee /etc/apt-fast.conf

rm -v /opt/mirrors-{debian,ubuntu}.txt

apt-fast update
#apt-fast full-upgrade

