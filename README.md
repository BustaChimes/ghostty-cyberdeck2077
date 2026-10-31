```
 ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗████████╗██╗   ██╗
██╔════╝ ██║  ██║██╔═══██╗██╔════╝╚══██╔══╝╚══██╔══╝╚██╗ ██╔╝
██║  ███╗███████║██║   ██║███████╗   ██║      ██║    ╚████╔╝
██║   ██║██╔══██║██║   ██║╚════██║   ██║      ██║     ╚██╔╝
╚██████╔╝██║  ██║╚██████╔╝███████║   ██║      ██║      ██║
 ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝      ╚═╝      ╚═╝
▓▒░░▒▓█ C ¥ B Ξ R P U N K   T E R M 1 N A L █▓▒░░▒▓░▒▓▒░▒▓░▒
```

<p align="center">
  <img src="https://img.shields.io/badge/SYSTEM_STATUS-ONLINE-fcee0a?style=for-the-badge&labelColor=0b0c10" alt="system status: online">
  <img src="https://img.shields.io/badge/PLATFORM-macOS_•_LINUX-00f0ff?style=for-the-badge&labelColor=0b0c10" alt="platform: macOS and Linux">
  <img src="https://img.shields.io/badge/POWERED_BY-GHOSTTY-ff2e97?style=for-the-badge&labelColor=0b0c10" alt="powered by Ghostty">
  <a href="LICENSE"><img src="https://img.shields.io/badge/LICENSE-MIT-fcee0a?style=for-the-badge&labelColor=0b0c10" alt="MIT license"></a>
</p>

<p align="center">
  <img src="screenshots/hero.gif" alt="GHOST//DECK — a Cyberpunk 2077 themed Ghostty terminal" width="800">
</p>

**A Cyberpunk 2077-style terminal for macOS and Linux, built on [Ghostty](https://ghostty.org).** Neon yellow, cyan, and magenta. A live CRT shader that glitches when you least expect it. A scrambled-text decode on every window you open. And every window flies its callsign: `GHOST//DECK`.

<p align="center">
  <img src="icons/Mono.png" width="128" alt="app icon">
</p>

## ▓▓ 01 // BOOT SEQUENCE ▓▓

This is what jacking in looks like:

```
> INITIALIZING GHOSTTY-CYBERPUNK ..................... [ OK ]
> LOADING SHADER :: cyberpunk.glsl v3 ................ [ OK ]
> SCANLINES ── ABERRATION ── VIGNETTE ── GRAIN ....... [ OK ]
> ARMING GLITCH SCHEDULER :: 7 MODES ................. [ OK ]
> PROMPT UPLINK :: starship ▶ ........................ [ OK ]
> CALLSIGN REGISTERED :: "GHOST//DECK" ............... [ OK ]

// ACCESS GRANTED :: WELCOME TO NIGHT CITY
```

Every new window opens with a randomized banner that decodes itself out of static — `// LINK ESTABLISHED`, `// ACCESS GRANTED`, `// UPLINK SYNCED` — in about a third of a second, whatever the length.

## ▓▓ 02 // INSTALLED WETWARE ▓▓

- **CRT glitch shader** (`shaders/cyberpunk.glsl`) — always-on scanlines, chromatic aberration, vignette, film grain, and a slow signal roll. On top of that, a scheduler rolls the dice every half-second and can fire one of **7 glitch modes**: horizontal band tear, RGB split spike, block displacement, vertical sync jitter, brightness flicker, glyph color corruption, and a rare full-frame invert flash. Frequency, intensity, and duration are all randomized — it never loops.
- **`decode`** — the scrambled-text reveal as a command. `decode "ACCESS GRANTED"` animates any text.
- **`cprun`** — wraps any command in the fiction: `cprun make -j8` prints `// EXECUTING :: make -j8`, runs it, then `// COMPLETE :: 0 :: 4.2s` in green — or `// FAILED` in red with the exit code.
- **Starship prompt** — yellow → cyan powerline segments with path and git status, a magenta clock pinned hard to the right edge, and a `▶` cursor that flips red when the last command flatlined.
- **Themed `ls` colors** — dirs yellow, executables green, media magenta, archives red, docs blue. Uses [eza](https://github.com/eza-community/eza) if you have it, degrades cleanly to stock `ls` (macOS or GNU) if you don't.
- **ssh that just works** — remote hosts don't know Ghostty's terminfo and will whine about it. A tiny wrapper sends `TERM=xterm-256color` to remotes only; your local TERM stays untouched.
- **The nameplate** — the window titles itself `GHOST//DECK`, and the Dock / launcher icon is swapped for one of three original icons (Mono / Window / Hazard). No stock branding — your deck flies its own colors.

## ▓▓ 03 // RIG REQUIREMENTS ▓▓

Minimum spec to run this ICE:

**macOS** (Apple Silicon)

- [Homebrew](https://brew.sh) — the installer uses it to pull:
  - [Ghostty](https://ghostty.org)
  - FiraCode Nerd Font
  - [Starship](https://starship.rs)
- zsh for your shell (the macOS default — you already have it)
- Optional chrome: `eza` for the full ls color treatment

**Linux** (Ubuntu / Debian, GNOME or KDE desktop)

- `sudo` + `apt` — the installer pulls:
  - [Ghostty](https://ghostty.org) — `apt install ghostty` on Ubuntu 26.04+ (distro package), otherwise the [Snap Store package](https://snapcraft.io/ghostty) (`snap install ghostty --classic`; snapd ships with Ubuntu)
  - FiraCode Nerd Font — official [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) release, installed per-user into `~/.local/share/fonts` and registered with fontconfig
  - [Starship](https://starship.rs) — from apt if your release packages it, otherwise the official installer (into `/usr/local/bin`)
- zsh — the installer `apt install`s it and offers to `chsh` you to it (the scripts themselves are plain bash, so a fresh box needs nothing but `git`)
- Optional chrome: `eza` (`sudo apt install eza` on Ubuntu 24.04+)

## ▓▓ 04 // JACK IN ▓▓

Three commands. Thirty seconds. Copy-paste as-is:

**macOS**

```sh
git clone https://github.com/BustaChimes/ghostty-cyberdeck2077.git
cd ghostty-cyberdeck2077
./install.sh
```

**Linux (Ubuntu / Debian)** — one line, safe to re-run (it pulls if the clone is already there):

```sh
sudo apt-get update && sudo apt-get install -y git && { git -C ~/ghostty-cyberdeck2077 pull --ff-only 2>/dev/null || git clone https://github.com/BustaChimes/ghostty-cyberdeck2077.git ~/ghostty-cyberdeck2077; } && ~/ghostty-cyberdeck2077/install.sh
```

The installer detects the OS (`uname`), checks dependencies, copies everything into `~/.config/ghostty/` and `~/.config/starship.toml`, adds three guarded lines to your `~/.zshrc`, and applies the icon. It is **idempotent** — safe to re-run — and any config it overwrites is backed up first as `<file>.pre-cyberpunk`.

Then open a new Ghostty window. `// ACCESS GRANTED`. (On Linux, if the installer just switched your shell to zsh, log out and back in first.)

### > platform split

`~/.config/ghostty/config` is shared by both platforms. Everything OS-specific lives in `~/.config/ghostty/platform.conf`, pulled in with Ghostty's `config-file` include. The installer copies the right one from `platform/`:

| | `platform/macos.conf` | `platform/linux.conf` |
|---|---|---|
| Titlebar | transparent, no proxy icon (`macos-titlebar-*`) | GTK default |
| App icon | `macos-icon = custom` | a `.desktop` launcher override in `~/.local/share/applications/` |
| Font | `font-thicken` (macOS-only option) | — |
| Shortcuts | Ghostty's Cmd defaults | Ctrl+Shift equivalents, pinned explicitly |

Theme, shader, prompt, and zsh bits are identical on both. Linux notes: `background-blur` only takes effect on KDE/KWin (GNOME just gets the 92% opacity), and the shader runs on OpenGL instead of Metal — same GLSL file.

### > ./flatline (uninstall)

```sh
./uninstall.sh
```

Restores your backups, strips the zshrc lines, resets the icon (on Linux: removes the launcher override). Ghostty, the font, and Starship stay installed. Like it never happened.

## ▓▓ 05 // TUNING THE ICE ▓▓

**Shader tunables** live at the top of `~/.config/ghostty/shaders/cyberpunk.glsl`:

| Constant | What it does |
|---|---|
| `GLITCH_CHANCE` | odds of a glitch per half-second window (default `0.08` — raise it if you want chaos) |
| `SCANLINE_STRENGTH` | how visible the CRT scanlines are (default `0.12`) |
| `INVERT_SHARE` | fraction of glitches upgraded to the full-frame invert flash (default `0.10`) |
| `ABERRATION_PX` / `VIGNETTE` / `GRAIN` | color fringe, edge darkening, noise floor |

Edit, then hit `Cmd+Shift+,` (Linux: `Ctrl+Shift+,`) to reload Ghostty's config. Instant feedback.

**Icon** — three variants ship in `icons/`. Swap anytime (macOS: Dock icon; Linux: app-grid / dock launcher):

```sh
~/.config/ghostty/apply-icon.sh Window.png   # or Mono.png / Hazard.png
```

**Banner** — set `DECODE_BANNER=0` in your environment to open windows in silence. `DECODE_COLOR` overrides the decode color:

```sh
DECODE_COLOR=$'\e[38;2;0;240;255m' decode "hello, choom"
```

## ▓▓ 06 // CORPO LEGAL ▓▓

> **Plain-language disclaimer, no lore:** this is a fan-made theme inspired by the *Cyberpunk 2077* aesthetic. It is **not affiliated with, endorsed by, or connected to CD Projekt Red** in any way. No CDPR assets are used — the icons are original artwork, and the colors are just colors.

MIT licensed — see [LICENSE](LICENSE). Now go make some noise, netrunner.
