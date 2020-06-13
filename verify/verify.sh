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
    T="$(mktemp)"                               # tar
    S="$(mktemp)"                               # sig
    trap "rm -f $T $S" 0

    cat > "$T"                                  # we need to read the tar twice
    sig="$(tar -ft "$T" | grep -m 1 '\.sig$')"  # grab the first filename that ends with .sig
    tar -xf "$T" "$sig" > "$S"                  # extract that file
    tar --to-command="gpg --verify $S" -xf "$T" # verify the remaining files TODO do we need to skip the sig?
    exit $?
    ;;
  2) # use %.sig to verify %
    T="$(mktemp -u)"
    U="$(mktemp -u)"
    tar -ft "$T" | sed -n '0,/.sig$/s///p' |
    trap "rm -f $T $U" 0
    mkfifo "$T"
    mkfifo "$U"
    #tar -ft - | tee "$T" | sed -n 's@.sig$@@ip' > "$U"
    tee "$U" |
    tar --sort=name -ft - | \
    tee "$T" | sed -n 's@.sig$@@ip' | diff --line-format=%= "$T" - |
    tar -xf .tar %.sig


    comm -12 <() <()
    tar -xf .tar % --to-command='bash -c "gpg --verify $TARFILENAME.sig -"'



    tar -xf large_file.tar.gz "full-path/to-the-file/in-the-archive/the-filename-you-want"
            diff 
	    # get filename without .sig extension > "$U"
            # print filenames that have a match in $T: 
	    # xargs -L 2 gpg --verify
	    '/.sig$/{file=sub(/.sig$/, "", $0); system("test -f "$file") && printf("%s  %s\n", $file $0)}' |
    
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

