# Asset sources and editable layers

This is the source register for the current prologue and Chapter I build. It records how the shipped PNG and WAV files were made; it is not a claim that outside reference pictures are licensed for redistribution.

| Runtime assets | Editable or traceable source | Status |
| --- | --- | --- |
| `prologue-asset-pack-v1/backgrounds`, `far`, `mid`, `front`, `props`, `characters`, `ui` | `prologue-asset-pack-v1/manifest.json`, `docs/prompts.json`, `docs/scene-layouts.json` and the source PNGs | Project-generated prototype art. The layered PNGs remain separately editable. |
| `chapter1-assets/control-walkway-layers-v1/*.png` | That folder's README and `storybook-original-scenes-v1/01-control-walkway.png` | Project-generated painting and extracted transparent layers. Godot places the wing, ring and dial separately. |
| `chapter1-assets/inverted-room-layers-v1/*.png` | That folder's README and `storybook-original-scenes-v1/02-inverted-room.png` | Project-generated painting and separate water, furniture and foreground layers. |
| `chapter1-assets/maintenance-shaft-layers-v1/*.png` | That folder's README and `storybook-original-scenes-v1/03-maintenance-shaft.png` | Project-generated painting and separate basket, rope and mechanism states. |
| `chapter1-assets/engine-room-layers-v1/*.png` | That folder's README and `storybook-original-scenes-v1/04-engine-room.png` | Project-generated painting and separate linkage, brake and stop layers. |
| `chapter1-assets/observatory-layers-v1/*.png` | That folder's README and `storybook-original-scenes-v1/05-observatory.png` | Project-generated painting and separate window, telescope and archive layers. |
| `chapter1-assets/characters/erin/*.png` | That folder's README and pose PNGs | Project-generated character poses; Godot crops and anchors them at runtime. |
| `prologue-asset-pack-v1/audio/*.wav` | `prologue-asset-pack-v1/audio/audio-manifest.json` | Original procedural synthesis recorded in the manifest. |
| Godot engine binary in Windows package | `GODOT_LICENSE.txt` | MIT licensed engine; engine notice accompanies the package. |

Reference images supplied during the art direction conversation guided the style. They are not copied into the runtime asset folders. Do not add third-party screenshots, fonts or sounds to the distributed build without recording their author, source URL, license and required credit here.

The layer PNGs are the editable source currently available in this repository; no native `.ora` or `.psd` source is present. When repainting a scene, retain the new native layered source beside its exported PNGs and update its folder README with the Godot node and placement correspondence. Review each generated asset and its service terms before a public commercial release.
