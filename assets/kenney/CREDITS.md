# Kenney artwork in Fieldwork

All packs below are by **Kenney**, released under **CC0 1.0**. They may be used and modified in commercial games. Original license files are included beside this document; [CC0 terms](https://creativecommons.org/publicdomain/zero/1.0/).

| Pack | Use | Original license |
| --- | --- | --- |
| [Furniture Kit](https://kenney.nl/assets/furniture-kit) | Desks, computers, beds, chairs, plants, shelves and kitchen furniture | [furniture-license.txt](furniture-license.txt) |
| [UI Pack 2.0](https://kenney.nl/assets/ui-pack) | Buttons, frames, controls, navigation icons and Kenney Future heading font | [ui-license.txt](ui-license.txt) |
| [Cursor Pack 1.1](https://kenney.nl/assets/cursor-pack) | Arrow, pointing hand, open/closed hand and placement target | [cursor-license.txt](cursor-license.txt) |

Downloaded from the official pack pages on 11 September 2026. [manifest.json](manifest.json) maps local files to pack originals. UI artwork is tinted and sliced in Godot; the progress track uses an atlas crop. Cursors are resized to 32×32 at runtime.

Furniture PNGs are transparent orthographic renders of the original GLB models. The desk combines the desk, monitor, keyboard and mouse. Selected source models live in `tools/art_sources/furniture/`. To reproduce the sprites from the repository root, run:

```sh
godot --path . --script tools/render_furniture.gd
godot --headless --path . --editor --import --quit
```

The first command needs a graphics display. Camera, lighting and crop settings are recorded in the script. The game loads only the resulting PNGs; the GLBs and bake script are excluded from exports. No remote asset request is made while playing.

The room plan, scientific instruments, staff portraits and field symbols remain Fieldwork's existing Godot/vector artwork, recolored to match these packs. Audio credits are maintained separately in [assets/audio/CREDITS.md](../audio/CREDITS.md).
