#! /usr/bin/env bash
set -euo pipefail

T="$(mktemp)"
tar -O "$T" -cf -
lrzip -z -U --outfile - "$T"

