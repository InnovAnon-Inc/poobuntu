#! /bin/bash
set -exu

mv -v `which gzip`{-old,}
mv -v `which gunzip`{-old,}
mv -v `which bzip2`{-old,}
mv -v `which xz`{-old,}

apt-fast purge --autoremove -y `cat poobuntu-dpkg.list`
apt-fast purge --autoremove -y apt-fast
add-apt-repository -r ppa:apt-fast/stable
apt purge --autoremove -y software-properties-common
apt purge --autoremove -y dialog apt-utils
apt clean
rm -rf /var/lib/apt/lists/*
rm -v poobuntu-dpkg.list /etc/profile.d/makeflags.sh

