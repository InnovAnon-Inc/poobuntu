# Use the official image as a parent image.
ARG OS
ARG VER
FROM $OS:$VER
ARG OS
ARG VER

RUN echo now building ${OS}:${VER} 2>&1

MAINTAINER Innovations Anonymous <InnovAnon-Inc@protonmail.com>
LABEL version="1.0"                                                     \
      maintainer="Innovations Anonymous <InnovAnon-Inc@protonmail.com>" \
      about="Ubuntu enhanced with parallelization hacks"                \
      org.label-schema.build-date=$BUILD_DATE                           \
      org.label-schema.license="PDL (Public Domain License)"            \
      org.label-schema.name="Parallelized Ubuntu"                       \
      org.label-schema.url="InnovAnon-Inc.github.io/poobuntu"           \
      org.label-schema.vcs-ref=$VCS_REF                                 \
      org.label-schema.vcs-type="Git"                                   \
      org.label-schema.vcs-url="https://github.com/InnovAnon-Inc/poobuntu"

ARG  DEBIAN_FRONTEND=noninteractive
ENV  DEBIAN_FRONTEND=${DEBIAN_FRONTEND}
ARG  TZ=UTC
ENV  TZ=$TZ
ENV  LANG='C.UTF-8'
ENV  LC_ALL='C.UTF-8'

# Disable Upstart
# TODO is /usr/sbin/policy-rc. supposed to be /usr/sbin/policy-rc.d
RUN dpkg-divert --local --rename --add /sbin/initctl \
 && ln -sfv /bin/true  /sbin/initctl                 \
 && ln -sfv /bin/false /usr/sbin/policy-rc.

# TODO these need to be reset at runtime and at child's build time
ARG  MAKEFLAGS
ARG  CMAKE_BUILD_PARALLEL_LEVEL
ENV  MAKEFLAGS=$MAKEFLAGS
ENV  CMAKE_BUILD_PARALLEL_LEVEL=$CMAKE_BUILD_PARALLEL_LEVEL

# Copy the file from your host to your current location.
COPY ./etc/apt/apt.conf.d/*          \
      /etc/apt/apt.conf.d/
COPY ./etc/dpkg.cfg.d/*              \
      /etc/dpkg.cfg.d/
COPY ./etc/profile.d/*               \
      /etc/profile.d/

# TODO list debian directory and grab latest version of netselect package

#      pcurl http://ftp.us.debian.org/debian/pool/main/n/netselect/netselect_0.3.ds1-28+b1_`dpkg --print-architecture`.deb \
#        netselect.deb          \
#      MIRRORS='pcurl mirrors.ubuntu.com/mirrors.txt'                                  ; \
#      MIRRORS='pcurl https://www.debian.org/mirror/list | grep -o '\''http://[^"]*'\' ; \


#RUN apt update \
# && apt install curl ca-certificates

COPY ./common/*                      \
      /common/
COPY ./poobuntu/*                    \
      /poobuntu/

# invalidate cache
COPY    invalidate.cache .
RUN  rm invalidate.cache

# install custom scripts
ARG REPO=https://raw.githubusercontent.com/InnovAnon-Inc/repo/master
ENV REPO=$REPO
ADD $REPO/install.sh        \
    $REPO/fawk.sh           \
    $REPO/apt-glob.sh       \
    $REPO/apt-list.sh       \
    $REPO/pcurl.sh          \
                /poobuntu/
ADD $REPO/delete.env        \
                /usr/local/bin/
#RUN chmod -v +x /usr/local/bin/*
RUN chmod -v +x /poobuntu/install.sh \
           /usr/local/bin/delete.env \
 && /poobuntu/install.sh             \
      apt-glob.sh \
      apt-list.sh \
      fawk.sh     \
      pcurl.sh

# install required software
RUN apt update
RUN apt install              \
      `/common/manual.list`  \
    `/poobuntu/dpkg.list`    \
    `/poobuntu/dpkg.glob`    \
    `/poobuntu/manual.list`  \
    `/poobuntu/manual.glob`

# redirect compression utils
# get parallel apt and friends
RUN /poobuntu/redirect.sh

# configure apt-fast to use the fastest mirrors
# update, upgrade
COPY ./usr/local/bin/upgrade.sh      \
      /usr/local/bin/
RUN /usr/local/bin/upgrade.sh

RUN /poobuntu/clean.sh

COPY ./poobuntu/test.sh \
      /poobuntu/
RUN if [ "$TEST" ] ; then \
      /poobuntu/test.sh   \
   || exit $? ; fi        \
 && rm -v /poobuntu/test.sh

