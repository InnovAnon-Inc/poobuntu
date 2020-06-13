#! /usr/bin/env bash
set -euo pipefail

#V=-v
V=

IFS= read -r cksum                                                     # Line #1
case "$cksum" in                                      # whitelist known programs
  md5sum|sha1sum|sha224sum|sha256sum|sha384sum|sha512sum|b2sum)
    ;;
  *) # unknown algorithm
    exit 1
    ;;
esac

# TODO verify options  --ignore-missing --quiet --status --strict -w, --warn

IFS= read -r mode                                                      # Line #2
case "$mode" in                                                     # protocol #
  0) # compute checksum
    "$cksum" -b | # TODO -b necessary?                # file contents from stdin
    awk '{print $1}'                 # we don't know the filename so truncate it
    exit $?                                       # -eo pipefail => exit success
    ;;
  1) # verify  checksum
    IFS= read -r hash                                     # read expected output
    "$cksum" -c <(awk '{printf("%s  -\n", $1)}' <<< "$hash") # read actual input
    exit $?                                       # -eo pipefail => exit success
    ;;
  2) # compute checksums
      helper="$(readlink -f "$0")"                                 # this script
      helper="${helper/.sh/-2.sh}"                          # -2 for protocol #2
      cksum=$cksum \
      tar --to-command="$helper" $V -xf -        # to-command replaces filenames
      exit $?                                     # -eo pipefail => exit success
    ;;
  3) # verify  checksums
    T="$(mktemp -d)"                                             # temp work dir
    trap "popd ; rm -rf "$T"" 0                                # cleanup on exit
    pushd "$T"                                                  # enter work dir

    #t="$T/t"
    #tee "$t" |
    #tar -tf - |
    #grep "$cksum"'s\?$' |
    #xargs -r tar -xf "$t"

    tar $V -xf -                                              # untar from stdin
    dirs=()
    for dir in "$cksum"{,s} ; do                 # expected values are in/under,
      [[ ! -e "$dir"  ]] ||                                   # e.g., md5sum{,s}
      dirs+=("$dir")
    done
    (( "${#dirs[@]}" ))  # sanity check: client sent at least one checksum file?
    find "${dirs[@]}" -type f -exec \
      "$cksum" -c {} +                # check hashes against the specified files
    exit $?                                       # -io pipefail => exit success
    ;;
  *) # unsupported protocol
    exit 1
    ;;
esac

