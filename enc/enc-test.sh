#! /usr/bin/env bash
set -ueo pipefail

{ echo 1 ; # compression
  echo 0 ; # encrypt
  echo 0 ; # mode
  gpg         \
    --encrypt \
    --recipient InnovAnon-Inc@protonmail.com \
  < enc.sh ;
} |
./enc.sh -v -x > enc.sh.enc
echo created cipher text

{ echo 1 ; # decompression
  echo 1 ; # decrypt
  echo 0 ; # mode
  cat enc.sh.enc ;
} |
./enc.sh -v -x > enc.sh.bkf
echo created plain text

rm -v enc.sh.enc

diff -q enc.sh{,.bkf}
rm -v enc.sh.bkf
echo success

