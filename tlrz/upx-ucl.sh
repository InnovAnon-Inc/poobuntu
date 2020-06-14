#! /usr/bin/env bash
set -euo pipefail

T="$(mktemp)"
trap "rm -f $T" 0

strip --strip-all "$T"
upx-ucl --ultra-brute --all-filters "$T"
cat "$T"

