#!/usr/bin/env bash
# ghostty-cyberpunk installer — idempotent, safe to re-run.
# macOS (Homebrew) or Linux (Ubuntu/Debian, apt + snap).
# Plain bash (macOS ships 3.2) so it runs on a fresh box before zsh is installed.
# Copies configs into place, never touches anything outside:
#   ~/.config/ghostty/  ~/.config/starship.toml  ~/.zshrc (3 guarded lines)
#   Linux only: ~/.local/share/fonts/FiraCodeNerdFont/ and one .desktop
#   launcher in ~/.local/share/applications/ (for the app icon)
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
GC="$HOME/.config/ghostty"
# ~/.zshrc lines this installer actually appended (so uninstall removes ONLY those)
MANIFEST="$GC/.cyberpunk-zshrc-added"
OS="$(uname -s)"

case "$OS" in
  Darwin) PLATFORM=macos ;;
  Linux)  PLATFORM=linux ;;
  *) echo "Unsupported OS: $OS (macOS and Ubuntu/Debian Linux only)" >&2; exit 1 ;;
esac

# One-time record of what was there before the first install, so uninstall can
# put it back. If a file did NOT exist, a ".pre-cyberpunk.none" sentinel says
# "nothing was here — remove on uninstall". Re-runs never overwrite either.
backup_once() {
  [[ -f "$1.pre-cyberpunk" || -f "$1.pre-cyberpunk.none" ]] && return 0
  if [[ -f "$1" ]]; then
    cp "$1" "$1.pre-cyberpunk"
    echo "   backed up $1 -> $1.pre-cyberpunk"
  else
    : > "$1.pre-cyberpunk.none"
  fi
}

# Append a line to ~/.zshrc only if $2 isn't found in it, and record what we added.
add_zshrc_line() {
  if ! grep -qF "$2" ~/.zshrc; then
    echo "$1" >> ~/.zshrc
    grep -qxF "$1" "$MANIFEST" 2>/dev/null || echo "$1" >> "$MANIFEST"
    echo "   added to ~/.zshrc: $1"
  fi
}

# True if apt has an installable candidate for package $1 (e.g. ghostty on Ubuntu 26.04+).
apt_has() {
  local cand
  cand="$(apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/ {print $2}')"
  [[ -n "$cand" && "$cand" != "(none)" ]]
}

deps_macos() {
  echo "== 1/5 dependencies (Homebrew)"
  if ! command -v brew >/dev/null; then
    echo "Homebrew is required. Install it from https://brew.sh then re-run ./install.sh" >&2
    exit 1
  fi
  [[ -d /Applications/Ghostty.app || -d "$HOME/Applications/Ghostty.app" ]] || brew install --cask ghostty
  # shellcheck disable=SC2010  # font filenames are plain ASCII; unchanged macOS check
  if ! ls ~/Library/Fonts /Library/Fonts 2>/dev/null | grep -qi "FiraCodeNerdFont"; then
    brew install --cask font-fira-code-nerd-font
  fi
  command -v starship >/dev/null || brew install starship
  command -v eza >/dev/null || echo "   (optional: 'brew install eza' for richer ls colors — falls back to built-in ls without it)"
}

deps_linux() {
  echo "== 1/5 dependencies (apt / snap — sudo may ask for your password)"
  if ! command -v apt-get >/dev/null; then
    echo "This installer supports Ubuntu/Debian (apt). Install Ghostty, FiraCode Nerd Font," >&2
    echo "Starship and zsh by hand, then re-run ./install.sh" >&2
    exit 1
  fi
  local -a need=()
  local p
  for p in zsh curl xz-utils fontconfig desktop-file-utils; do
    dpkg -s "$p" >/dev/null 2>&1 || need+=("$p")
  done
  if (( ${#need[@]} )); then
    sudo apt-get update
    sudo apt-get install -y "${need[@]}"
  fi

  # Ghostty: the distro package where it exists (Ubuntu 26.04+), otherwise the
  # Snap Store package (snapd ships with Ubuntu; classic confinement, auto-updates).
  if ! command -v ghostty >/dev/null && [[ ! -x /snap/bin/ghostty ]]; then
    if apt_has ghostty; then
      sudo apt-get install -y ghostty
    elif command -v snap >/dev/null; then
      sudo snap install ghostty --classic
    else
      echo "No Ghostty package found (needs Ubuntu 26.04+ apt, or snapd)." >&2
      echo "See https://ghostty.org/docs/install/binary for other options, then re-run ./install.sh" >&2
      exit 1
    fi
  fi

  # FiraCode Nerd Font, per-user via fontconfig (official Nerd Fonts release).
  if ! fc-list 2>/dev/null | grep -qi "FiraCode Nerd Font"; then
    local fdir="$HOME/.local/share/fonts/FiraCodeNerdFont"
    mkdir -p "$fdir"
    curl -fL --retry 3 -o "$fdir/FiraCode.tar.xz" \
      https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.tar.xz
    tar -xJf "$fdir/FiraCode.tar.xz" -C "$fdir"
    rm -f "$fdir/FiraCode.tar.xz"
    fc-cache -f "$fdir" >/dev/null
    echo "   installed FiraCode Nerd Font -> $fdir"
  fi

  # Starship: apt if this release packages it, else the official installer (-> /usr/local/bin).
  if ! command -v starship >/dev/null; then
    if apt_has starship; then
      sudo apt-get install -y starship
    else
      curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
    fi
  fi

  if ! command -v eza >/dev/null; then
    if apt_has eza; then
      echo "   (optional: 'sudo apt install eza' for richer ls colors — falls back to GNU ls without it)"
    else
      echo "   (optional: install eza for richer ls colors — falls back to GNU ls without it)"
    fi
  fi

  # The zsh bits need zsh as the login shell (Ghostty launches your login shell).
  local zsh_path login_shell
  zsh_path="$(command -v zsh)"
  login_shell="$(getent passwd "$USER" | cut -d: -f7)"
  if [[ "${login_shell##*/}" != zsh ]]; then
    local reply=""
    [[ -t 0 ]] && read -r -p "   Your login shell is ${login_shell:-unknown}. Switch it to zsh now? [y/N] " reply
    if [[ "$reply" == [yY]* ]]; then
      chsh -s "$zsh_path"
      echo "   login shell -> $zsh_path (takes effect at your next login)"
    else
      echo "   NOTE: the prompt/banner need zsh. Switch later with: chsh -s $zsh_path"
    fi
  fi
}

"deps_$PLATFORM"

echo "== 2/5 config files -> ~/.config/ghostty and ~/.config/starship.toml"
mkdir -p "$GC/shaders" "$GC/icons" "$HOME/.config"
backup_once "$GC/config"
backup_once "$GC/platform.conf"
backup_once "$GC/cyberpunk.zsh"
backup_once "$HOME/.config/starship.toml"
cp "$HERE/config"                   "$GC/config"
cp "$HERE/platform/$PLATFORM.conf"  "$GC/platform.conf"
cp "$HERE/shaders/cyberpunk.glsl"   "$GC/shaders/cyberpunk.glsl"
cp "$HERE/cyberpunk.zsh"            "$GC/cyberpunk.zsh"
cp "$HERE/apply-icon.sh"            "$GC/apply-icon.sh"
cp "$HERE"/icons/*.png              "$GC/icons/"
cp "$HERE/starship.toml"            "$HOME/.config/starship.toml"
chmod +x "$GC/apply-icon.sh"

echo "== 3/5 write the absolute icon path into the config"
# Ghostty's macos-custom-icon does not expand ~, so it must be your real home dir.
# (-i.tmp + rm works with both BSD and GNU sed; no-op on Linux, which has no placeholder.)
sed -i.tmp "s|__HOME__|$HOME|" "$GC/platform.conf" && rm -f "$GC/platform.conf.tmp"

echo "== 4/5 ~/.zshrc (each line added only if missing)"
touch ~/.zshrc "$MANIFEST"
# shellcheck disable=SC2016  # written to ~/.zshrc literally, expands there
add_zshrc_line 'eval "$(starship init zsh)"'              'starship init zsh'
add_zshrc_line 'export ZLE_RPROMPT_INDENT=0'              'ZLE_RPROMPT_INDENT'
add_zshrc_line 'source ~/.config/ghostty/cyberpunk.zsh'   'ghostty/cyberpunk.zsh'

echo "== 5/5 apply the app icon"
"$GC/apply-icon.sh" "$GC/icons/Mono.png"

echo ""
echo ">> DONE. Open a new Ghostty window to jack in."
echo ">> Swap icons anytime: ~/.config/ghostty/apply-icon.sh Window.png   (or Hazard.png)"
