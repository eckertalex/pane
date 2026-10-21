#!/bin/sh
set -eu

cd "$(dirname "$0")"

# --- Unpack Arguments --------------------------------------------------------
mode="debug"
compiler="clang"
for arg in "$@"; do
    case "$arg" in
        debug|release) mode="$arg" ;;
        clang|gcc) compiler="$arg" ;;
        *)
            echo "usage: $0 [debug|release] [clang|gcc]" >&2
            exit 1
            ;;
    esac
done

# --- Compile/Link Line Definitions -------------------------------------------
CC="${CC:-$compiler}"
FLAGS="$(cat compile_flags.txt)"

PLATFORM_FLAGS=""
LIBS=""
case "$(uname -s)" in
    Darwin)
        # The unity build includes the Cocoa backend, so compile it all as Objective-C
        PLATFORM_FLAGS="-x objective-c"
        LIBS="-framework Cocoa"
        ;;
    Linux)
        # sudo dnf install pkgconf libX11-devel wayland-devel
        # sudo apt install pkg-config libx11-dev libwayland-dev
        if command -v pkg-config >/dev/null 2>&1; then
            LIBS="$(pkg-config --cflags --libs x11 wayland-client)"
        else
            LIBS="-lX11 -lwayland-client"
        fi
        ;;
    *)
        echo "unsupported platform: $(uname -s)" >&2
        exit 1
        ;;
esac

# --- Choose Mode -------------------------------------------------------------
echo "[$compiler compile]"
case "$mode" in
    debug)
        echo "[debug mode]"
        MODE_FLAGS="-O0 -g -DBUILD_DEBUG=1"
        ;;
    release)
        echo "[release mode]"
        MODE_FLAGS="-O2 -g -DBUILD_DEBUG=0"
        ;;
esac

# --- Build -------------------------------------------------------------------
mkdir -p build
$CC $FLAGS $PLATFORM_FLAGS $MODE_FLAGS src/pane/pane_main.c -o build/pane $LIBS
