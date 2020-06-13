#! /usr/bin/env bash
set -euo pipefail

#xargs printf "%s\n" |

#while read line ; do
#  echo "$line" 1>&2
#  echo "$line"
#done |

sort -u               |
xargs                 \
netselect -s 20 -t 40 |
awk '! A[$2] {A[$2]=1 ; print $2}'

