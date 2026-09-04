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

CFG="$HOME/.config/ghostty/config"
mkdir -p ~/.config/ghostty
cp "$SRC" ~/.config/ghostty/icon.png

echo "== strip any stale Finder custom icon"
xattr -d com.apple.FinderInfo /Applications/Ghostty.app 2>/dev/null || true
rm -f "/Applications/Ghostty.app/Icon"$'\r' 2>/dev/null || true

echo "== point Ghostty at the icon natively"
sed -i '' '/^macos-icon/d;/^macos-custom-icon/d' "$CFG"
printf '\n# ---------- App icon ----------\nmacos-icon = custom\nmacos-custom-icon = %s/.config/ghostty/icon.png\n' "$HOME" >> "$CFG"

echo "== relaunch"
osascript -e 'quit app "Ghostty"' 2>/dev/null || true
sleep 1
killall Dock
open -a Ghostty
echo "Done. The Dock icon is the custom one while Ghostty runs; Ghostty re-applies it on every launch."
