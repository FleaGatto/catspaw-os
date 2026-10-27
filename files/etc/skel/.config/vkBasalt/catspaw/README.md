# CATSPAW // SHADE — cursed shader pack

Five ReShade `.fx` post-process shaders for **vkBasalt**, the Vulkan display
layer you already run for the Sober purple LUT. They repaint the final frame of
any Vulkan game. The **Home** key toggles the look on/off in-game.

This is a *display layer*, the same class of thing as MangoHud — it doesn't
touch game files, memory, or the network. (It's the usual way people run ReShade
on Linux, CS2 included; I can't speak for Valve's anti-cheat policy with
certainty, but vkBasalt is external to the game process.)

## Looks

| look | what it does |
|---|---|
| `hazard` | posterize to black + hazard-yellow, Sobel edges outlined in yellow |
| `thermal` | predator heat-map (dark → magenta → red → yellow → white) |
| `nightvision` | green-phosphor goggles: gain, grain, scanlines, round vignette |
| `crt` | barrel curve, RGB aperture mask, scanlines, brightness roll |
| `glitch` | datamosh — block tears + RGB split, pulsing on a beat |
| `crt-hazard` | hazard-vision seen through the CRT tube (stacked) |

`nightvision`, `crt`, `glitch` animate (they use vkBasalt's `timer`).

## Use

The `catspaw-shade` launcher (in `~/.local/bin`) wires up the env vars per
game type:

```sh
catspaw-shade list                       # show looks
catspaw-shade steam   glitch             # prints Steam launch-option string
catspaw-shade flatpak hazard org.vinegarhq.Sober     # Roblox/Sober
catspaw-shade flatpak thermal com.ogulniega.launcher # Minecraft
catspaw-shade run     crt -- <some-vulkan-game>
catspaw-shade test    hazard             # try it on a spinning vkcube
```

### CS2 (Steam, native)

```sh
catspaw-shade steam glitch
```

Paste the printed line into **CS2 → Properties → Launch Options**, launch, press
**Home** to toggle. To switch looks, point `VKBASALT_CONFIG_FILE` at a different
`conf/*.conf`.

### Sober (Roblox) / Minecraft (flatpak)

`catspaw-shade flatpak <look> <app-id>` grants the sandbox read access to this
shader dir for that run and sets the env — so it works despite flatpak's
isolated `/usr` and config dirs. The `ReShade.fxh` header is bundled right here
in the shader dir for exactly that reason (the sandbox can't see the host's
`/usr/share/gamescope` copy).

## Files

- `Catspaw*.fx` — the shaders (self-contained, only `#include "ReShade.fxh"`)
- `ReShade.fxh` — the standard header, bundled so flatpaks can reach it
- `conf/<look>.conf` — one vkBasalt config per look (toggleKey = Home)

## If a look does nothing

vkBasalt compiles shaders at launch and logs to the game's stderr. Run from a
terminal (or the Steam launch wrapper) and look for `vkBasalt` lines — a compile
error there names the file and line. The effect is skipped on error; the game
runs normally either way.
