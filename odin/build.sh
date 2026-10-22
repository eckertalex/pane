#!/bin/sh
set -eu

cd "$(dirname "$0")"

# --- Unpack Arguments --------------------------------------------------------
mode="debug"
for arg in "$@"; do
    case "$arg" in
        debug|release) mode="$arg" ;;
        *)
            echo "usage: $0 [debug|release]" >&2
            exit 1
            ;;
    esac
done

# --- Platform ----------------------------------------------------------------
case "$(uname -s)" in
    Darwin) ;;
    Linux)
        # Odin's Xlib bindings link these too, not just X11
        # sudo dnf install libX11-devel libXcursor-devel libXfixes-devel libXrandr-devel libXi-devel
        # sudo apt install libx11-dev libxcursor-dev libxfixes-dev libxrandr-dev libxi-dev
        ;;
    *)
        echo "unsupported platform: $(uname -s)" >&2
        exit 1
        ;;
esac

# --- Choose Mode -------------------------------------------------------------
case "$mode" in
    debug)
        echo "[debug mode]"
        MODE_FLAGS="-debug -o:none"
        ;;
    release)
        echo "[release mode]"
        MODE_FLAGS="-o:speed -disable-assert"
        ;;
esac

# --- Build -------------------------------------------------------------------
mkdir -p build
odin build src/pane -out:build/pane -vet $MODE_FLAGS
