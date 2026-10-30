#!/bin/sh
# usage: ./build.sh [debug|release]
set -eu

cd "$(dirname "$0")"

flags="-vet"
case "${1:-debug}" in
    debug) flags="$flags -debug -o:none" ;;
    release) flags="$flags -o:speed" ;;
    *)
        echo "usage: $0 [debug|release]" >&2
        exit 2
        ;;
esac

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

mkdir -p build
odin build src/pane -out:build/pane $flags
