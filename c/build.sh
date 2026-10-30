#!/bin/sh
# usage: ./build.sh [debug|release]
# CC picks the compiler, clang by default
set -eu

cd "$(dirname "$0")"

flags="-std=c23 -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wundef -Wno-unused-function -D_GNU_SOURCE"
case "${1:-debug}" in
    debug) flags="$flags -O0 -g -DBUILD_DEBUG=1" ;;
    release) flags="$flags -O2 -g -DBUILD_DEBUG=0" ;;
    *)
        echo "usage: $0 [debug|release]" >&2
        exit 2
        ;;
esac

case "$(uname -s)" in
    Darwin)
        # The unity build includes the Cocoa backend, so compile it all as Objective-C
        flags="$flags -x objective-c -mmacosx-version-min=14.0"
        libs="-framework Cocoa"
        ;;
    Linux)
        # sudo dnf install pkgconf libX11-devel
        # sudo apt install pkg-config libx11-dev
        if command -v pkg-config >/dev/null 2>&1; then
            libs="$(pkg-config --cflags --libs x11)"
        else
            libs="-lX11"
        fi
        ;;
    *)
        echo "unsupported platform: $(uname -s)" >&2
        exit 1
        ;;
esac

# Absolute paths, so errors resolve from the repo root too
mkdir -p build
${CC:-clang} $flags -I"$PWD/src" "$PWD/src/pane/pane_main.c" -o build/pane $libs
