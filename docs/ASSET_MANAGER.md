# Asset Manager

Holdfast now uses JSON manifests as the source of truth for runtime asset metadata.

## Files

- `assets/config/manifest.json`
- `assets/config/tiles.json`
- `assets/config/tilemaps.json`

## Current schema

- `images`
  - Stable asset IDs mapped to file paths and rendering options.
- `atlases`
  - Atlas path plus `tileWidth` and `tileHeight`.
- `animationSets`
  - Sprite-sheet metadata, animation frame ranges, draw anchors, and hitbox config.
- `tiles`
  - Walkability, collision, ground atlas frames, and overlay sprites.
- `tilemaps`
  - Registered tilemap assets. Current runtime support is `tiled_lua` through `STI`.

## Runtime API

Implemented in `src/core/assetmanager.lua`.

- `getImage(id)`
- `getAtlas(id)`
- `getQuad(atlasId, tileId)`
- `getAnimationSet(id)`
- `getTileDefinition(tileType)`
- `getTileRenderData(tileType, tx, ty, timeSeconds)`
- `getTilemap(id)`
- `list(section)`

## UI/editor contract

The upcoming asset manager UI should edit these JSON files instead of patching Lua modules directly.

Editor-safe targets:

- animation hitboxes
- sprite anchors and draw offsets
- tile collision
- tile overlays and atlas variants
- registered tilemaps

## Tilemap note

`STI` is integrated for Tiled Lua exports. This avoids writing a custom map loader now, but still leaves the project-owned manifest layer in control of map registration and metadata.
