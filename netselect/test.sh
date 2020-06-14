#! /usr/bin/env bash
set -euxo pipefail

H=0
while getopts "H" arg ; do
  case $arg in
    H) # indicates tests which cannot be run on the host
      H=1
      ;;
    -)
      break
      ;;
    *) # invalid option
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))
(( ! $# ))

#NCF="${NCF:--N}"
NCF="${NCF:--w 3}"

(( "$H" )) || exit 0

D="$(mktemp -d)"
trap "rm -fr $D" 0

L="$D/l"
#O="$D/o"
#V="$D/v"

# populate test data
sort > "$L" << EOF
lmaddox.chickenkiller.com
InnovAnon-Inc.chickenkiller.com
bing.com
duckduckgo.com
google.com

EOF
[[ -s "$L" ]]

nc $NCF localhost 27400 < "$L" | # server will echo a subset of its input
sort | # client sort order for comm
awk '{print}END{exit(!NR)}' |
#tee "$O" |
comm -13 "$L" - | # lines unique to output
#tee "$V"
awk '{print}END{exit(NR)}' |

#[[ -s "$O" ]]
#[[ ! -s "$V" ]]

../usr/local/bin/upgrade.sh

