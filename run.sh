#! /bin/bash
set -exu
[ $# -eq 0 -o $# -eq 1 ]

if ! command -v dockerd ; then
	command -v wget ||
	apt install wget
	wget -nc https://download.docker.com/linux/static/stable/x86_64/docker-19.03.8.tgz
	[ -d docker-19.03.8 ] ||
	tar xf docker-19.03.8.tgz
	install docker/* /usr/local/bin/
fi

docker version ||
dockerd &

if [ -z ${1+x} ] ; then
	CMD='docker build -t poobuntu .'
else
	#CMD="docker build -t poobuntu-$1 --build-arg DOCKER_TAG=$1 ."
	CMD="docker build -t poobuntu-$1 --build-arg VERSION=$1 ."
fi

sudo             -- \
nice -n -20      -- \
sudo -u `whoami` -- \
$CMD

