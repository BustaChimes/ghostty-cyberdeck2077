#!/bin/zsh
# Swap the Ghostty app icon.
# Usage: ./apply-icon.sh Mono.png     (or Window.png / Hazard.png, or a path to any 1024px PNG)
set -e

NAME="${1:-Mono.png}"
HERE="${0:A:h}"
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

APP="/Applications/Ghostty.app"
[[ -d "$APP" ]] || APP="$HOME/Applications/Ghostty.app"

CFG="$HOME/.config/ghostty/config"
mkdir -p ~/.config/ghostty
cp "$SRC" ~/.config/ghostty/icon.png

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
