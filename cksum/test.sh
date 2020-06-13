#! /usr/bin/env bash
set -euxo pipefail

for cksum in md5sum sha{1,224,256,384,512}sum ; do
  rm -f "${cksum}s"
  { echo $cksum ;
    echo 0      ;
    cat "$0"    ;
  } |
  netcat -N -q 0 localhost 27500 |
  tee ${cksum}s

  { echo $cksum ;
    echo 1      ;
    cat ${cksum}s ;
    cat "$0"    ;
  } |
  netcat -N -q 0 localhost 27500
  rm ${cksum}s

  { echo $cksum ;
    echo 2      ;
    tar cf - .  ;
  } |
  netcat -N -q 0 localhost 27500 |
  tee ${cksum}s

  { echo $cksum ;
    echo 3      ;
    tar cf - .  ;
  } |
  netcat -N -q 0 localhost 27500
  rm ${cksum}s
done

