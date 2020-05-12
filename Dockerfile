# Use the official image as a parent image.
FROM ubuntu:latest

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

ENV TZ America/Chicago

# Run the command inside your image filesystem.
RUN apt update
RUN apt install -y apt-utils
RUN apt install -y software-properties-common
RUN add-apt-repository ppa:apt-fast/stable
RUN apt update
RUN apt install -y apt-fast
RUN apt-fast full-upgrade -y
# Copy the file from your host to your current location.
COPY poobuntu-dpkg.list .
RUN apt-fast install -y `cat poobuntu-dpkg.list`

RUN cp -v   `which gzip`   `which gzip`-old
RUN cp -v   `which gunzip` `which gunzip`-old
RUN cp -v   `which bzip2`  `which bzip2`-old
RUN cp -v   `which xz`     `which xz`-old
RUN ln -fsv `which pigz`   `which gzip`
RUN ln -fsv `which unpigz` `which gunzip`
RUN ln -fsv `which pbzip2` `which bzip2`
# TODO bunzip2
RUN ln -fsv `which pixz`   `which xz`
# TODO unxz
#RUN ln -fsv `which plzip`  `which lzip`

COPY makeflags.sh /etc/profile.d

COPY poobuntu-clean.sh .

