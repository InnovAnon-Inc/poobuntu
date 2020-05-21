# Use the official image as a parent image.
ARG DOCKER_TAG=latest
FROM ubuntu:$DOCKER_TAG
MAINTAINER Innovations Anonymous <InnovAnon-Inc@protonmail.com>

LABEL version="1.0"
LABEL maintainer="Innovations Anonymous <InnovAnon-Inc@protonmail.com>"
LABEL about="Ubuntu enhanced with parallelization hacks"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.license="PDL (Public Domain License)"
LABEL org.label-schema.name="Parallelized Ubuntu"
LABEL org.label-schema.url="InnovAnon-Inc.github.io/poobuntu"
LABEL org.label-schema.vcs-ref=$VCS_REF
LABEL org.label-schema.vcs-type="Git"
LABEL org.label-schema.vcs-url="https://github.com/InnovAnon-Inc/poobuntu"

ENV DEBIAN_FRONTEND noninteractive
ENV TZ America/Chicago

COPY makeflags.sh  /etc/profile.d
COPY 02innovanon   /etc/apt/apt.conf.d

# Disable Upstart
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sfv /bin/true  /sbin/initctl
RUN ln -sfv /bin/false /usr/sbin/policy-rc.

RUN apt update
RUN apt install wget
RUN wget -q http://ftp.us.debian.org/debian/pool/main/n/netselect/netselect_0.3.ds1-28+b1_arm64.deb
RUN dpkg --force-architecture --force-depends -i netselect_0.3.ds1-28+b1_arm64.deb
RUN rm -v netselect_0.3.ds1-28+b1_arm64.deb
RUN netselect -s 20 -t 40 `wget -qO- mirrors.ubuntu.com/mirrors.txt` \
  | awk 'BEGIN{printf "_APTMGR=apt\nDOWNLOADBEFORE=true\nMIRRORS=( '\''"}{printf "%s,", $1}END{printf "http://lmaddox.chickenkiller.com:3142'\'' )"}' \
  > /tmp/apt-fast.conf
RUN dpkg -r netselect

# Run the command inside your image filesystem.
RUN apt install dialog apt-utils
RUN apt install software-properties-common
RUN add-apt-repository ppa:apt-fast/stable
RUN apt update
RUN apt install apt-fast
RUN mv -v /tmp/apt-fast.conf /etc/apt-fast.conf
RUN apt-fast full-upgrade
# Copy the file from your host to your current location.
COPY poobuntu-dpkg.list .
RUN apt-fast install `cat poobuntu-dpkg.list`

RUN ! command -v gzip   ||      cp -v   `which gzip`   `which gzip`-old
RUN ! command -v gunzip ||      cp -v   `which gunzip` `which gunzip`-old
RUN ! command -v bzip2  ||      cp -v   `which bzip2`  `which bzip2`-old
RUN ! command -v xz     ||      cp -v   `which xz`     `which xz`-old
RUN if command -v gzip   ; then ln -fsv `which pigz`   `which gzip`   ; else ln -sv `which pigz`   /usr/bin/gzip   ; fi
RUN if command -v gunzip ; then ln -fsv `which unpigz` `which gunzip` ; else ln -sv `which unpigz` /usr/bin/gunzip ; fi
RUN if command -v bzip2  ; then ln -fsv `which pbzip2` `which bzip2`  ; else ln -sv `which pbzip2` /usr/bin/bzip2  ; fi
# TODO bunzip2
RUN if command -v xz     ; then ln -fsv `which pixz`   `which xz`     ; else ln -sv `which pixz`   /usr/bin/xz     ; fi
# TODO unxz
#RUN ln -fsv `which plzip`  `which lzip`

COPY poobuntu-clean.sh .

