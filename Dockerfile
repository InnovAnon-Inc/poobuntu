# Use the official image as a parent image.
#ARG DOCKER_TAG=latest
#FROM ubuntu:$DOCKER_TAG
ARG VERSION=latest
FROM ubuntu:$VERSION
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

ARG DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_FRONTEND ${DEBIAN_FRONTEND} \
    TZ=America/Chicago                 \
    LANG='C.UTF-8'                     \
    LC_ALL='C.UTF-8'                   \
    MAKEFLAGS=-j$(nproc)

# Copy the file from your host to your current location.
#COPY makeflags.sh         /etc/profile.d/
#RUN /bin/echo -e "`cat /etc/profile.d/makeflags.sh`\n\n`cat /etc/bash.bashrc`"    > /etc/bash.bashrc
#RUN /bin/echo -e "`cat /etc/profile.d/makeflags.sh`\n\n`cat /root/.bashrc`"       > /root/.bashrc
#RUN /bin/echo -e "`cat /etc/profile.d/makeflags.sh`\n\n`cat /root/.bash_profile`" > /root/.bash_profile
COPY 02minimal 02compress /etc/apt/apt.conf.d/
COPY netselect.awk poobuntu-dpkg.list redirect.sh poobuntu-clean.sh ./

# TODO is /usr/sbin/policy-rc. supposed to be /usr/sbin/policy-rc.d
# TODO list debian directory and grab latest version of netselect package

# Disable Upstart
RUN dpkg-divert --local --rename --add /sbin/initctl \
 && ln -sfv /bin/true  /sbin/initctl                 \
 && ln -sfv /bin/false /usr/sbin/policy-rc.          \
 \
 && apt update       \
 && apt install wget \
 && wget -q http://ftp.us.debian.org/debian/pool/main/n/netselect/netselect_0.3.ds1-28+b1_`dpkg --print-architecture`.deb \
 && dpkg -i netselect_0.3.ds1-28+b1_`dpkg --print-architecture`.deb  \
 && rm -v netselect_0.3.ds1-28+b1_`dpkg --print-architecture`.deb    \
 && netselect -s 20 -t 40 `wget -qO- mirrors.ubuntu.com/mirrors.txt` \
  | awk -f netselect.awk   \
  | tee /tmp/apt-fast.conf \
 && rm -v netselect.awk    \
 && dpkg -r netselect      \
 \
 && apt install dialog apt-utils                \
 && apt install software-properties-common      \
 && add-apt-repository ppa:apt-fast/stable      \
 && apt update                                  \
 && apt install apt-fast                        \
 && mv -v /tmp/apt-fast.conf /etc/apt-fast.conf \
 && apt-fast full-upgrade                       \
 && apt-fast install `grep -v '^[\^#]' poobuntu-dpkg.list` \
 && ./redirect.sh \
 && rm -v redirect.sh

#RUN ! command -v gzip   ||      cp -v   `which gzip`   `which gzip`-old
#RUN ! command -v gunzip ||      cp -v   `which gunzip` `which gunzip`-old
#RUN ! command -v bzip2  ||      cp -v   `which bzip2`  `which bzip2`-old
#RUN ! command -v xz     ||      cp -v   `which xz`     `which xz`-old
#RUN if command -v gzip   ; then ln -fsv `which pigz`   `which gzip`   ; else ln -sv `which pigz`   /usr/bin/gzip   ; fi
#RUN if command -v gunzip ; then ln -fsv `which unpigz` `which gunzip` ; else ln -sv `which unpigz` /usr/bin/gunzip ; fi
#RUN if command -v bzip2  ; then ln -fsv `which pbzip2` `which bzip2`  ; else ln -sv `which pbzip2` /usr/bin/bzip2  ; fi
## TODO bunzip2
#RUN if command -v xz     ; then ln -fsv `which pixz`   `which xz`     ; else ln -sv `which pixz`   /usr/bin/xz     ; fi
## TODO unxz
##RUN ln -fsv `which plzip`  `which lzip`


#RUN ./poobuntu-clean.sh

