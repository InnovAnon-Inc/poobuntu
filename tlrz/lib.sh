#! /usr/bin/env bash
set -euo

T="$(mktemp)"
trap "rm -f $T" 0

cat > "$T"
strip -R .comment "$T"
strip --strip-debug "$T"
strip --strip-unneeded "$T"
cat "$T"

