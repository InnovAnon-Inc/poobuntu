#! /usr/bin/env bash
set -euxo pipefail

[[ ! `command -v localepurge` ]] ||
localepurge

K=()
for k in /{acng,common,netselect,poobuntu}/dpkg.{list,glob} ; do
  [[ -e  $k ]] || continue
  K+=(  "$k")
done
(( ! "${#K[@]}" )) ||
apt-mark auto   `${K[@]}`

P=()
for k in /{acng,common,netselect,poobuntu}/manual.{list,glob} ; do
  [[ -e  $k ]] || continue
  P+=(  "$k")
done
(( ! "${#P[@]}" )) ||
apt-mark manual `${P[@]}`

(( ${#K[@]} + ${#P[@]} == 0 )) ||
rm -v ${K[@]} ${P[@]}
#rm -fv /poobuntu/{dpkg,manual}.{list,glob}

apt autoremove
apt clean
rm -rf /var/lib/apt/lists/*

# Remove info, man and docs
rm -rf /usr/share/info/* \
       /usr/share/man/*  \
       /usr/share/doc/*

