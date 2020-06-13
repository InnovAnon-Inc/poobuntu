#! /usr/bin/env bash
set -euo pipefail

# no param, self-contained sig on stdin

# param self-contained sig


# param detached sig, verify contents of stdin
# param detached sig, verify contents of params, possibly also stdin

# %.sig: %

# TODO verify options  --ignore-missing --quiet --status --strict -w, --warn

IFS= read -r mode
case "$mode" in
  0) # self contained sig on stdin
    gpg --verify --output - -
    exit $?
    ;;
  1) # 1 sig file, verify the rest (input is tar)
    T="$(mktemp -d)"
    trap "rm -rf $T" 0

    F="$T/f"
    #S="$T/s"

    sig="$(tee "$F" | tar -tf - |
           grep -m 1 '\.gpg$')"
    [[ "$sig" ]]
    #tar -O "$S" -xf "$F" "$sig"
    #tar -xf "$F" "$sig" > "$S"
    tar -xf "$F" "$sig"
    S="$sig"
    [[ -s "$S" ]]

    set -f
    tar --to-command="$(printf -- '%q ' gpg --verify --output - "$S" -)" \
	--exclude="$sig" \
        -xf "$F"
    exit $?
    ;;
  2) # use %.sig to verify %
    T="$(mktemp)" # list of files with sigs
    U="$(mktemp)" # tar
    D="$(mktemp -d)" # extracted sigs
    trap "rm -rf $D $T $U" 0

    ##sed -n '0,/.gpg$/s///p' | # find %.sig
    #tee "$U" | # keep the tar for later
    #tar -tf - | # list files in archive
    #sed -n 's/\.gpg$//ip' | # find %.sig
    #tee "$T" | # keep % for later
    #sed 's/$/\.gpg/' |  # reappend .sig
    #( cd "$D" && xargs -r tar -xf "$U" --) # extract %.sig
    ( cd "$D" && tar -T <(
    tee "$U" |
    tar -tf - |
    sed -n 's/\.gpg$//ip' |
    tee "$T" |
    sed 's/$/\.gpg/') -xf "$U") # extract %.sig
    [[ -s "$U" ]]
    [[ -s "$T" ]]

    #xargs -r tar \
    #  --to-command="$(printf -- '%q ' bash -c \
    #  "gpg --verify --output - $D/\$TAR_FILENAME.gpg" -)" \
    #  -xf "$U" < "$T"
    tar \
      --to-command="$(printf -- '%q ' bash -c \
      "gpg --verify --output - $D/\$TAR_FILENAME.gpg" -)" \
      -T "$T" -xf "$U"
    exit $?
    ;;
  *) # unsupported protocol
    exit 1
    ;;
esac

