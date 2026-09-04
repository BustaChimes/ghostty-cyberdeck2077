# ghostty-cyberpunk

**A Cyberpunk 2077-style terminal for macOS, built on [Ghostty](https://ghostty.org).** Neon yellow/cyan/magenta everywhere, a live CRT shader with random glitches, a text-decode animation on every new window — and it disguises itself as plain old Terminal.app in your Dock and title bar.

<!-- add screenshots/hero.png and uncomment:
![screenshot](screenshots/hero.png)
-->

<p align="center">
  <img src="icons/Mono.png" width="128" alt="app icon">
</p>

## Features

- **CRT glitch shader** (`shaders/cyberpunk.glsl`) — always-on scanlines, chromatic aberration, vignette, grain, and a slow roll, plus **7 randomized glitch modes**: horizontal band tear, RGB split spike, block displacement, vertical sync jitter, brightness flicker, glyph color corruption, and a rare full-frame invert flash. Frequency, intensity, and duration are all randomized.
- **Decode animation** — new windows greet you with a scrambled-text reveal (`// ACCESS GRANTED :: NODE …`). The `decode` command animates any text; `cprun <command>` wraps a command in `// EXECUTING` / `// COMPLETE` decode lines with a timer.
- **Starship prompt** — yellow → cyan powerline segments with git status, and a magenta clock pinned to the right edge.
- **Themed `ls` colors** — dirs yellow, executables green, media magenta, archives red, docs blue. Uses [eza](https://github.com/eza-community/eza) if installed, falls back to plain macOS `ls` colors if not.
- **ssh fix** — remote hosts don't know Ghostty's terminfo; a tiny wrapper sends `TERM=xterm-256color` to remotes only, so ssh just works.
- **The Terminal disguise** — window title says `Terminal`, and the Dock icon is swapped for one of three original icons (Mono / Window / Hazard) that pass for a stock system utility. Nobody has to know.

## Requirements

- macOS on Apple Silicon
- [Homebrew](https://brew.sh) — the installer uses it to fetch:
  - [Ghostty](https://ghostty.org)
  - FiraCode Nerd Font
  - [Starship](https://starship.rs)
- zsh (macOS default)
- Optional: `eza` for the full ls color treatment

## Install

```sh
git clone https://github.com/BustaChimes/ghostty-cyberpunk.git
cd ghostty-cyberpunk
./install.sh
```

That's it — the installer checks dependencies, copies everything into `~/.config/ghostty/` and `~/.config/starship.toml`, adds three guarded lines to your `~/.zshrc`, and applies the icon. It's **idempotent** (safe to re-run) and backs up any config it overwrites as `<file>.pre-cyberpunk`.

To remove it all:

```sh
./uninstall.sh
```

## Customize

**Shader tunables** — top of `~/.config/ghostty/shaders/cyberpunk.glsl`:

| Constant | What it does |
|---|---|
| `GLITCH_CHANCE` | odds of a glitch per half-second window (default `0.08`) |
| `SCANLINE_STRENGTH` | how visible the CRT scanlines are (default `0.12`) |
| `INVERT_SHARE` | fraction of glitches upgraded to the full-frame invert flash (default `0.10`) |
| `ABERRATION_PX` / `VIGNETTE` / `GRAIN` | color fringe, edge darkening, noise |

Edit, then reload Ghostty config with `Cmd+Shift+,`.

**Icon** — three variants ship in `icons/`. Swap anytime:

```sh
~/.config/ghostty/apply-icon.sh Window.png   # or Mono.png / Hazard.png
```

**Banner** — set `DECODE_BANNER=0` in your environment to disable the new-window animation. `DECODE_COLOR` overrides the decode color, e.g. `DECODE_COLOR=$'\e[38;2;0;240;255m' decode "hello"`.

## Credits / disclaimer

Fan-made theme inspired by the *Cyberpunk 2077* aesthetic. **Not affiliated with, endorsed by, or connected to CD Projekt Red.** No CDPR assets are used — the icons are original artwork, and the colors are just colors.

MIT licensed — see [LICENSE](LICENSE).
