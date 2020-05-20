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

# Disable Upstart
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sfv /bin/true /sbin/initctl
RUN ln -sfv /bin/false /usr/sbin/policy-rc.

# Run the command inside your image filesystem.
RUN apt update
RUN apt install -y dialog apt-utils
RUN apt install -y software-properties-common
RUN add-apt-repository ppa:apt-fast/stable
RUN apt update
RUN apt install -y apt-fast
RUN apt-fast full-upgrade -y
# Copy the file from your host to your current location.
COPY poobuntu-dpkg.list .
RUN apt-fast install -y `cat poobuntu-dpkg.list`

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

COPY makeflags.sh /etc/profile.d
COPY 02proxy      /etc/apt/apt.conf.d

COPY poobuntu-clean.sh .

