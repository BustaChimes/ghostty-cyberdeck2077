#!/usr/bin/env bash
# Swap the Ghostty app icon.
# Usage: ./apply-icon.sh Mono.png     (or Window.png / Hazard.png, or a path to any 1024px PNG)
#   macOS: Ghostty's native macos-custom-icon (written to platform.conf).
#   Linux: a per-user .desktop launcher override whose Icon= points at the PNG.
set -e

NAME="${1:-Mono.png}"
HERE="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$NAME" ]]; then
  SRC="$NAME"
elif [[ -f "$HERE/icons/$NAME" ]]; then
  SRC="$HERE/icons/$NAME"
elif [[ -f "$HERE/$NAME" ]]; then
  SRC="$HERE/$NAME"
else
  echo "icon not found: $NAME (looked in ./, $HERE/icons/, $HERE/)" >&2
  exit 1
fi

GC="$HOME/.config/ghostty"
mkdir -p "$GC"
cp "$SRC" "$GC/icon.png"

apply_macos() {
  local APP="/Applications/Ghostty.app"
  [[ -d "$APP" ]] || APP="$HOME/Applications/Ghostty.app"
  local CFG="$GC/platform.conf"
  touch "$CFG"

  echo "== strip any stale Finder custom icon"
  xattr -d com.apple.FinderInfo "$APP" 2>/dev/null || true
  rm -f "$APP/Icon"$'\r' 2>/dev/null || true

  echo "== point Ghostty at the icon natively"
  sed -i '' '/^# ---------- App icon ----------$/d;/^macos-icon/d;/^macos-custom-icon/d' "$CFG"
  printf '\n# ---------- App icon ----------\nmacos-icon = custom\nmacos-custom-icon = %s/.config/ghostty/icon.png\n' "$HOME" >> "$CFG"

  if [[ "$TERM_PROGRAM" == ghostty ]]; then
    # Quitting Ghostty from inside Ghostty would kill this very script.
    echo "Done. Running inside Ghostty, so skipping the relaunch —"
    echo "restart Ghostty (or Cmd+Shift+, to reload the config) to apply the icon."
  else
    echo "== relaunch"
    osascript -e 'quit app "Ghostty"' 2>/dev/null || true
    sleep 1
    killall Dock
    open -a Ghostty
    echo "Done. The Dock icon is the custom one while Ghostty runs; Ghostty re-applies it on every launch."
  fi
}

apply_linux() {
  local apps="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
  local icon="$GC/icon.png"
  local src="" d f
  local -a dirs
  IFS=: read -ra dirs <<< "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  # Find the launcher the Ghostty package installed (apt/source or snap).
  for d in "${dirs[@]}" /var/lib/snapd/desktop; do
    for f in com.mitchellh.ghostty.desktop ghostty_ghostty.desktop; do
      [[ -f "$d/applications/$f" ]] && { src="$d/applications/$f"; break 2; }
    done
  done

  # A same-named file in ~/.local/share/applications shadows the system one,
  # so the app grid / dock show one Ghostty entry — with our icon.
  local dest="$apps/${src##*/}"
  [[ -n "$src" ]] || dest="$apps/com.mitchellh.ghostty.desktop"
  mkdir -p "$apps"

  echo "== write launcher override -> $dest"
  {
    echo "# GHOST//DECK icon override — written by ~/.config/ghostty/apply-icon.sh"
    if [[ -n "$src" ]]; then
      # Repoint every Icon= (incl. desktop actions) and any snap BAMF hint at this copy.
      sed -e "s|^Icon=.*|Icon=$icon|" \
          -e "s|/var/lib/snapd/desktop/applications/|$apps/|g" "$src"
    else
      printf '%s\n' '[Desktop Entry]' 'Type=Application' 'Name=Ghostty' \
        'Comment=A terminal emulator' 'Exec=ghostty' "Icon=$icon" \
        'Categories=System;TerminalEmulator;' 'Terminal=false' \
        'StartupNotify=true' 'StartupWMClass=com.mitchellh.ghostty'
    fi
  } > "$dest.tmp"
  # Ghostty's windows report app id com.mitchellh.ghostty; make sure the
  # launcher claims them so the dock uses this icon for running windows.
  if grep -q '^StartupWMClass=' "$dest.tmp"; then
    mv "$dest.tmp" "$dest"
  else
    awk '{ print } !done && $0 == "[Desktop Entry]" { print "StartupWMClass=com.mitchellh.ghostty"; done = 1 }' \
      "$dest.tmp" > "$dest"
    rm -f "$dest.tmp"
  fi
  echo "$dest" > "$GC/.cyberpunk-desktop-file"
  command -v update-desktop-database >/dev/null && update-desktop-database "$apps" 2>/dev/null || true

  echo "Done. The launcher/dock icon updates for newly opened Ghostty windows;"
  echo "if a pinned dock icon looks stale, unpin + re-pin Ghostty or log out and back in."
}

case "$(uname -s)" in
  Darwin) apply_macos ;;
  Linux)  apply_linux ;;
  *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac
