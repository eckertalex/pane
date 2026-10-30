#!/bin/sh
set -eu

cd "$(dirname "$0")"

# --- Arguments ---------------------------------------------------------------
versions=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        c|cpp|odin) versions="$versions $1" ;;
        *) break ;;
    esac
    shift
done

versions="${versions:-c cpp odin}"

# --- Build -------------------------------------------------------------------
status=0
for version in $versions; do
    echo "=== $version ===" >&2
    ./"$version"/build.sh "$@" || status=1
    echo >&2
done

exit "$status"
