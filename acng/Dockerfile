# Use the official image as a parent image.
ARG OS
ARG VER
FROM $OS:$VER
ARG OS
ARG VER
#FROM sameersbn/apt-cacher-ng:latest

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

# configs
COPY ./etc/apt/apt.conf.d/*          \
      /etc/apt/apt.conf.d/
COPY ./etc/dpkg.cfg.d/*              \
      /etc/dpkg.cfg.d/
COPY ./etc/profile.d/*               \
      /etc/profile.d/

# invalidate cache
COPY    invalidate.cache .
RUN  rm invalidate.cache

# install custom scripts
ARG REPO=https://raw.githubusercontent.com/InnovAnon-Inc/repo/master
ENV REPO=$REPO
ADD $REPO/fawk.sh     /usr/local/bin/fawk
ADD $REPO/apt-glob.sh /usr/local/bin/apt-glob
ADD $REPO/apt-list.sh /usr/local/bin/apt-list
RUN chmod -v +x       /usr/local/bin/fawk     \
                      /usr/local/bin/apt-glob \
                      /usr/local/bin/apt-list


# install required software
COPY ./common/manual.list            \
      /common/
RUN rm -v /etc/apt/apt.conf.d/02proxy      \
 && apt update                             \
 && apt install                            \
    $(/common/manual.list)

# poo
ADD $REPO/delete.env  /usr/local/bin/
COPY ./poobuntu/redirect.sh                \
      /poobuntu/
RUN chmod -v +x       /usr/local/bin/delete.env \
 &&   /poobuntu/redirect.sh                \
 && rm -v /poobuntu/redirect.sh

# specific deps
COPY   ./acng/manual.list            \
       ./acng/dpkg.list              \
       ./acng/dpkg.glob              \
        /acng/
RUN apt install                            \
      $(/acng/manual.list)                 \
      $(/acng/dpkg.list)                   \
      $(/acng/dpkg.glob)

# install apt-fast
RUN add-apt-repository ppa:apt-fast/stable \
      --update                             \
 && apt install apt-fast                   \
 && echo apt-fast >> /acng/manual.list

COPY        ./acng/scheduler.txt /
#USER signal-user
RUN crontab /scheduler.txt
#USER root
RUN rm -v   /scheduler.txt

# configure apt-fast to use the fastest mirrors
# update, upgrade
COPY ./usr/local/bin/upgrade.sh      \
      /usr/local/bin/
COPY ./acng/netselect.awk            \
      /acng/
#RUN   /usr/local/bin/upgrade.sh

# minimizeA
# TODO
#COPY ./poobuntu/clean.sh             \
#      /poobuntu/
#RUN   /poobuntu/clean.sh
 
COPY ./poobuntu/test.sh \
      /poobuntu/
RUN if [ "$TEST" ] ; then \
      /poobuntu/test.sh   \
   || exit $? ; fi        \
 && rm -v /poobuntu/test.sh

COPY ./acng/entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
