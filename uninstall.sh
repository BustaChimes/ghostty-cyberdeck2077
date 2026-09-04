#!/bin/zsh
# ghostty-cyberpunk uninstaller — reverses install.sh.
# Restores the .pre-cyberpunk backups install.sh made (or removes the files if
# there was nothing there before), and strips the lines it added to ~/.zshrc.
set -e
GC="$HOME/.config/ghostty"

restore_or_remove() {
  if [[ -f "$1.pre-cyberpunk" ]]; then
    mv "$1.pre-cyberpunk" "$1"
    echo "   restored $1 from backup"
  elif [[ -f "$1" ]]; then
    rm "$1"
    echo "   removed $1"
  fi
}

echo "== restore configs"
restore_or_remove "$GC/config"
restore_or_remove "$GC/cyberpunk.zsh"
restore_or_remove "$HOME/.config/starship.toml"
rm -f "$GC/shaders/cyberpunk.glsl" "$GC/apply-icon.sh" "$GC/icon.png"
rm -rf "$GC/icons"
rmdir "$GC/shaders" 2>/dev/null || true

echo "== remove the 3 lines from ~/.zshrc"
if [[ -f ~/.zshrc ]]; then
  cp ~/.zshrc ~/.zshrc.pre-uninstall
  grep -vF -e 'eval "$(starship init zsh)"' \
           -e 'export ZLE_RPROMPT_INDENT=0' \
           -e 'source ~/.config/ghostty/cyberpunk.zsh' \
           ~/.zshrc.pre-uninstall > ~/.zshrc || true
  echo "   (previous version kept at ~/.zshrc.pre-uninstall)"
fi

echo "== reset the Ghostty app icon"
xattr -d com.apple.FinderInfo /Applications/Ghostty.app 2>/dev/null || true
touch /Applications/Ghostty.app 2>/dev/null || true
killall Dock 2>/dev/null || true

echo ""
echo ">> Uninstalled. Open a new terminal window (Ghostty falls back to its defaults,"
echo ">> or to your restored config if you had one before installing)."
