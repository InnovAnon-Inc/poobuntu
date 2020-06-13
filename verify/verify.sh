#! /usr/bin/env bash
set -euo pipefail



gpg --verify

# no param, self-contained sig on stdin

# param self-contained sig


# param detached sig, verify contents of stdin
# param detached sig, verify contents of params, possibly also stdin

# %.sig: %




  Assume that the first argument is a signed file and verify it without generating any output.  With no arguments, the signature packet
              is read from STDIN.  If only one argument is given, the specified file is expected to include a complete signature.

              With  more  than one argument, the first argument should specify a file with a detached signature and the remaining files should con‐
              tain the signed data. To read the signed data from STDIN, use '-' as the second filename.  For security reasons, a detached signature
              will not read the signed material from STDIN if not explicitly specified





# TODO verify options  --ignore-missing --quiet --status --strict -w, --warn

IFS= read -r mode
case "$mode" in
  0) # self contained sig on stdin
    gpg --verify --outfile - -
    exit $?
    ;;
  1) # 1 sig file, verify the rest (input is tar)
    T="$(mktemp -d)"
    trap "rm -rf $T" 0

    F="$T/f"
    S="$T/s"

    sig="$(tee "$F" | tar -ft - |
           grep -m 1 '\.sig$')"
    [[ "$sig" ]]
    tar -xf "$F" "$sig" > "$S"
    [[ -s "$S" ]]

    set -f
    tar --to-command="$(printf -- '%q ' gpg --verify --outfile - "$S" -)" \
	--exclude="$sig" \
        -xf "$T"
    exit $?
    ;;
  2) # use %.sig to verify %
    T="$(mktemp)" # list of sigs
    U="$(mktemp)" # tar
    D="$(mktemp -d)" # extracted sigs
    trap "rm -rf $D $T $U" 0

    tee "$U" | # keep the tar for later
    tar -ft - | # list files in archive
    sed -n '0,/.sig$/s///p' | # find %.sig
    tee "$T" # keep % for later
    sed 's/$/.sig/' | # reappend .sig
    xargs -r tar -C "$D" -xf # extract %.sig

    xargs -r tar --to-command='gpg --verify --outfile - '"$D/"'"$TARFILENAME.sig" -' \
        -xf "$U" < "$T"
    exit $?
    ;;
      



	  # compute checksum
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

