#!/bin/zsh
# ghostty-cyberpunk uninstaller — reverses install.sh.
# Restores the .pre-cyberpunk backups install.sh made (or removes files it
# installed fresh), and strips ONLY the ~/.zshrc lines the installer added.
set -e
GC="$HOME/.config/ghostty"
MANIFEST="$GC/.cyberpunk-zshrc-added"

restore_or_remove() {
  if [[ -f "$1.pre-cyberpunk" ]]; then
    mv "$1.pre-cyberpunk" "$1"
    echo "   restored $1 from backup"
  elif [[ -f "$1.pre-cyberpunk.none" ]]; then
    rm -f "$1" "$1.pre-cyberpunk.none"
    echo "   removed $1 (nothing was there before install)"
  elif [[ -f "$1" ]]; then
    rm "$1"
    echo "   removed $1"
  fi
}

echo "== remove the ~/.zshrc lines the installer added"
if [[ -f "$MANIFEST" && -s "$MANIFEST" && -f ~/.zshrc ]]; then
  cp ~/.zshrc ~/.zshrc.pre-uninstall
  grep -vxF -f "$MANIFEST" ~/.zshrc.pre-uninstall > ~/.zshrc || true
  echo "   removed $(wc -l < "$MANIFEST" | tr -d ' ') line(s); previous version kept at ~/.zshrc.pre-uninstall"
else
  echo "   no lines recorded as installer-added — ~/.zshrc left untouched"
fi
rm -f "$MANIFEST"

echo "== restore configs"
restore_or_remove "$GC/config"
restore_or_remove "$GC/platform.conf"
restore_or_remove "$GC/cyberpunk.zsh"
restore_or_remove "$HOME/.config/starship.toml"
rm -f "$GC/shaders/cyberpunk.glsl" "$GC/apply-icon.sh" "$GC/icon.png"
rm -rf "$GC/icons"
rmdir "$GC/shaders" "$GC" 2>/dev/null || true

echo "== reset the Ghostty app icon"
if [[ "$(uname -s)" == Darwin ]]; then
  APP="/Applications/Ghostty.app"
  [[ -d "$APP" ]] || APP="$HOME/Applications/Ghostty.app"
  xattr -d com.apple.FinderInfo "$APP" 2>/dev/null || true
  touch "$APP" 2>/dev/null || true
  killall Dock 2>/dev/null || true
else
  # Linux: drop the .desktop override apply-icon.sh wrote; the package's own launcher takes over.
  DESKTOP_FILE="$(cat "$GC/.cyberpunk-desktop-file" 2>/dev/null || true)"
  if [[ -n "$DESKTOP_FILE" && -f "$DESKTOP_FILE" ]] && grep -q '^# GHOST//DECK icon override' "$DESKTOP_FILE"; then
    rm -f "$DESKTOP_FILE"
    echo "   removed $DESKTOP_FILE"
    command -v update-desktop-database >/dev/null && update-desktop-database "${DESKTOP_FILE:h}" 2>/dev/null || true
  fi
  # Fonts/Ghostty/Starship stay installed (other things may use them).
fi
rm -f "$GC/.cyberpunk-desktop-file"
rmdir "$GC" 2>/dev/null || true

echo ""
echo ">> Uninstalled. Open a new terminal window (Ghostty falls back to its defaults,"
echo ">> or to your restored config if you had one before installing)."
