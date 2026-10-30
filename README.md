# pane

## Goal

- Build something fun, learn handmade style
- Learn: memory, arenas, pointers, systems programming
- Not: platform API expertise
- 2D game, real art assets, not pixel art
- Toggleable debug overlay: FPS, frame times, tweakable values

## Decisions

- Odin
- SDL3: window, input, audio, GPU
- Own arena, as Odin's context allocator
- Own 2D renderer on SDL GPU
- Own immediate mode UI, game and debug
- FreeType + HarfBuzz
- Game: 2D, for the kids, idea open

## Now

- C23 version in `c`
- Base: arenas, temp scopes, scratch arenas, OS memory
- Window manager: macOS, Win32, X11
- Black window

## Versions

- `c`: C23, the original
- `cpp`: C version as C++20, C style
- `odin`: C version ported to Odin, no SDL
- `handmade`: old Handmade Hero code, reference

## Build

Each folder has a `build.sh` (and `build.bat` for Windows) that builds into its own `build/` folder.

```sh
./build.sh                  # c, cpp and odin, debug
./build.sh release          # c, cpp and odin, release
./build.sh odin             # name versions first to pick them

c/build.sh release          # c/build/pane
cpp/build.sh release        # cpp/build/pane
odin/build.sh release       # odin/build/pane
```

Every `build.sh` takes `debug` (the default) or `release`. C uses clang unless `CC` says otherwise, C++ uses clang++ unless `CXX` does, e.g. `CC=gcc c/build.sh`.

On Windows, `build.bat` takes the same `debug`/`release`, with clang only.

## Options considered

### Language

- C23
- C++20, C style
- Odin

### Platform

- Own window manager
- SDL3
- GLFW
- raylib

### Renderer

- Own per OS: Metal, D3D11, GL
- SDL3 GPU
- raylib

### UI

- Own immediate mode UI
- Dear ImGui
- Clay

### Game

- Top-down walk around
- Side-scroller
- Checkers, with AI
- Battleship, with AI

## Next

- Odin black window
- Port arena to Odin
- Frame loop, input
- 2D renderer: quads, textures
- Text: FreeType + HarfBuzz
- Immediate mode UI
- Debug overlay
- Game
