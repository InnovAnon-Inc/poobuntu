#! /bin/bash
set -exu

if command -v gzip-old   ; then mv -v `which gzip`{-old,}   ; else rm -v `which gzip`   ; fi
if command -v gunzip-old ; then mv -v `which gunzip`{-old,} ; else rm -v `which gunzip` ; fi
if command -v bzip2-old  ; then mv -v `which bzip2`{-old,}  ; else rm -v `which bzip2`  ; fi
if command -v xz-old     ; then mv -v `which xz`{-old,}     ; else rm -v `xz`           ; fi

apt-fast purge `cat poobuntu-dpkg.list`
apt-fast purge apt-fast
add-apt-repository -r ppa:apt-fast/stable
apt purge software-properties-common dialog apt-utils
apt clean
rm -rf /var/lib/apt/lists/*
rm -v poobuntu-dpkg.list /etc/profile.d/makeflags.sh /etc/apt/apt.conf.d/02innovanon /etc/apt-fast.conf

