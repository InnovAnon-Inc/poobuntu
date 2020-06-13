#! /usr/bin/env bash
set -euxo pipefail

. `command -v delete.env`
(( ! $# ))

if (( ! "$D" )) ; then

! command -v gzip   ||      cp -v   `which gzip`   `which gzip`-old
! command -v gunzip ||      cp -v   `which gunzip` `which gunzip`-old
! command -v bzip2  ||      cp -v   `which bzip2`  `which bzip2`-old
! command -v xz     ||      cp -v   `which xz`     `which xz`-old
if command -v gzip   ; then ln -fsv `which pigz`   `which gzip`   ; else ln -sv `which pigz`   /usr/bin/gzip   ; fi
if command -v gunzip ; then ln -fsv `which unpigz` `which gunzip` ; else ln -sv `which unpigz` /usr/bin/gunzip ; fi
if command -v bzip2  ; then ln -fsv `which pbzip2` `which bzip2`  ; else ln -sv `which pbzip2` /usr/bin/bzip2  ; fi
# TODO bunzip2
if command -v xz     ; then ln -fsv `which pixz`   `which xz`     ; else ln -sv `which pixz`   /usr/bin/xz     ; fi
# TODO unxz
#ln -fsv `which plzip`  `which lzip`

else

if command -v gzip-old   ; then mv -v `which gzip`{-old,}   ; else rm -v `which gzip`   ; fi
if command -v gunzip-old ; then mv -v `which gunzip`{-old,} ; else rm -v `which gunzip` ; fi
if command -v bzip2-old  ; then mv -v `which bzip2`{-old,}  ; else rm -v `which bzip2`  ; fi
if command -v xz-old     ; then mv -v `which xz`{-old,}     ; else rm -v `which xz`     ; fi

fi

