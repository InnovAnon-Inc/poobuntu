#! /usr/bin/env bash
set -euo pipefail

      
     	"$cksum" |
        awk -v "TFN=$TAR_FILENAME" \
            '$2 == "-" {printf "%s  %s\n", $1, TFN} $2 != "-" {print ; exit 2}'

