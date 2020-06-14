# Use the official image as a parent image.
ARG OS
ARG VER
#FROM debian:latest
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
ENV  MAKEFLAGS=$MAKEFLAGS
ENV  CMAKE_BUILD_PARALLEL_LEVEL=$CMAKE_BUILD_PARALLEL_LEVEL

# Copy the file from your host to your current location.
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
RUN chmod -v +x       /usr/local/bin/apt-glob   \
                      /usr/local/bin/apt-list

COPY ./common/manual.list            \
      /common/

# for now: to install pkgs
RUN mv -v /etc/apt/apt.conf.d/02proxy \
                         /tmp/02proxy \
 && apt update                        \
 && apt install                       \
       $(/common/manual.list)

# poo
ADD $REPO/delete.env  /usr/local/bin/
COPY      ./poobuntu/redirect.sh                \
           /poobuntu/
RUN chmod -v +x       /usr/local/bin/delete.env \
 &&        /poobuntu/redirect.sh                \
 && rm -v  /poobuntu/redirect.sh

# specific deps
COPY ./lrzdct/manual.list         \
      /lrzdct/
RUN apt install                       \
    $(/lrzdct/manual.list)

# upgrade and start using proxy
RUN apt full-upgrade                  \ 
 && mv -v                /tmp/02proxy \
          /etc/apt/apt.conf.d/02proxy

# configure server
COPY     ./lrzdct/inetd.conf /etc/inetd.d/
COPY     ./lrzdct/service    /tmp/service
RUN      cat                    /tmp/service  \
                             >> /etc/services \
 &&      rm -v                  /tmp/service
 #&& chattr +i /etc/inetd.d/inetd.conf

COPY        ./lrzdct/scheduler.txt /
#USER signal-user
RUN crontab /scheduler.txt
#USER root
RUN rm -v   /scheduler.txt

# minimize
COPY ./poobuntu/clean.sh            \
      /poobuntu/
RUN   /poobuntu/clean.sh

COPY ./poobuntu/test.sh \
      /poobuntu/
RUN if [ "$TEST" ] ; then \
      /poobuntu/test.sh   \
   || exit $? ; fi        \
 && rm -v /poobuntu/test.sh

#RUN touch /var/run/rinetd.pid \
# && chown -v nobody:nogroup   \
#          /var/run/rinetd.pid

# start server
# TODO periodically check mirrors
#ENTRYPOINT ["/usr/bin/env", "start-stop-daemon", "--start", "--chuid", "nobody:nogroup", "--exec", "/usr/bin/env", "--", "rinetd", "--conf-file", "/etc/inetd.conf", "--foreground"]
#ENTRYPOINT ["/usr/bin/env", "start-stop-daemon", "--start", "--exec", "/usr/bin/env", "--", "rinetd", "--conf-file", "/etc/inetd.conf", "--foreground"]
COPY ./lrzdct/lrzdct.sh   \
      /lrzdct/
RUN echo INETD_OPTS=--debug >> /etc/default/inetutils-inetd



#RUN systemctl enable inetutils-inetd
#ENTRYPOINT ["/usr/bin/env", "start-stop-daemon", "--start", "--exec", "/usr/bin/env", "--", "inetutils-inetd", "--help"]
#ENTRYPOINT ["/etc/init.d/inetutils-inetd", "start"]
COPY ./lrzdct/entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

