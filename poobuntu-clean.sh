#! /bin/bash
set -exu

if command -v gzip-old   ; then mv -v `which gzip`{-old,}   ; else rm -v `which gzip`   ; fi
if command -v gunzip-old ; then mv -v `which gunzip`{-old,} ; else rm -v `which gunzip` ; fi
if command -v bzip2-old  ; then mv -v `which bzip2`{-old,}  ; else rm -v `which bzip2`  ; fi
if command -v xz-old     ; then mv -v `which xz`{-old,}     ; else rm -v `which xz`     ; fi

# TODO test new changes
[[ ! `command -v localepurge` ]] || localepurge

apt-fast purge `grep -v '^[\^#]' poobuntu-dpkg.list`
apt-fast purge apt-fast dialog curl ca-certificates

rm -fv /etc/apt/sources.list.d/apt-fast*.list
#add-apt-repository -r ppa:apt-fast/stable

apt purge software-properties-common apt-utils gnupg gnupg-agent lsb-release
apt clean
rm -rf /var/lib/apt/lists/*
#rm -v poobuntu-clean.sh             poobuntu-dpkg.list \
#      /etc/profile.d/makeflags.sh   /etc/apt-fast.conf \
#      /etc/apt/apt.conf.d/02minimal /etc/apt/apt.conf.d/02compress

# Remove info, man and docs
rm -rf /usr/share/info/*
rm -rf /usr/share/man/*
rm -rf /usr/share/doc/*

rm -v poobuntu-clean.sh             poobuntu-dpkg.list             \
      /etc/apt/apt.conf.d/02minimal /etc/apt/apt.conf.d/02compress \
      /usr/local/bin/pcurl

