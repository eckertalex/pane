#!/bin/sh
set -eu

cd "$(dirname "$0")"

# --- Arguments ---------------------------------------------------------------
mode="debug"
compiler="clang"
action="build"

while [ "$#" -gt 0 ]; do
    case "$1" in
        debug|release) mode="$1" ;;
        clang|gcc|cc) compiler="$1" ;;
        build|run) action="$1" ;;
        --)
            shift
            break
            ;;
        *)
            echo "usage: $0 [debug|release] [clang|gcc|cc] [build|run] [-- args...]" >&2
            exit 2
            ;;
    esac
    shift
done

if [ "$action" != "run" ] && [ "$#" -gt 0 ]; then
    echo "error: program arguments require the 'run' action" >&2
    exit 2
fi

# --- Compile/Link Line Definitions -------------------------------------------
cc_cflags_gcc=""
cc_cflags_clang="-fdiagnostics-absolute-paths"
cc_common="-std=c23 -I../src -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wundef -Wno-unused-function -D_GNU_SOURCE"
cc_debug="-O0 -g -DBUILD_DEBUG=1 $cc_common"
cc_release="-O2 -g -DBUILD_DEBUG=0 $cc_common"

# --- Platform Settings -------------------------------------------------------
cc_platform=""
cc_os_gfx=""
case "$(uname -s)" in
    Darwin)
        # The unity build includes the Cocoa backend, so compile it all as Objective-C
        cc_platform="-x objective-c -mmacosx-version-min=14.0"
        cc_os_gfx="-framework Cocoa"
        ;;
    Linux)
        # sudo dnf install pkgconf libX11-devel
        # sudo apt install pkg-config libx11-dev
        if command -v pkg-config >/dev/null 2>&1; then
            cc_os_gfx="$(pkg-config --cflags --libs x11)"
        else
            cc_os_gfx="-lX11"
        fi
        ;;
    *)
        echo "unsupported platform: $(uname -s)" >&2
        exit 1
        ;;
esac

# --- Choose Compile Line -----------------------------------------------------
if   [ "$compiler" = "gcc" ];   then echo "[gcc compile]";   cc_compiler="${CC:-gcc} $cc_cflags_gcc"
elif [ "$compiler" = "clang" ]; then echo "[clang compile]"; cc_compiler="${CC:-clang} $cc_cflags_clang"
elif [ "$compiler" = "cc" ];    then echo "[cc compile]";    cc_compiler="${CC:-cc}"
fi
if   [ "$mode" = "debug" ];   then echo "[debug mode]";   compile="$cc_compiler $cc_platform $cc_debug"
elif [ "$mode" = "release" ]; then echo "[release mode]"; compile="$cc_compiler $cc_platform $cc_release"
fi

# --- Build -------------------------------------------------------------------
mkdir -p build
cd build
$compile ../src/pane/pane_main.c $cc_os_gfx -o pane
cd ..

# --- Run ---------------------------------------------------------------------
if [ "$action" = "run" ]; then
    exec ./build/pane "$@"
fi
