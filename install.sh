#!/bin/zsh
# ghostty-cyberpunk installer — idempotent, safe to re-run.
# Copies configs into place, never touches anything outside:
#   ~/.config/ghostty/  ~/.config/starship.toml  ~/.zshrc (3 guarded lines)
set -e
HERE="${0:A:h}"
GC="$HOME/.config/ghostty"

# Keep a one-time backup of a file before we first overwrite it.
# The backup name is fixed, so re-running install never clobbers your true original.
backup_once() {
  [[ -f "$1" && ! -f "$1.pre-cyberpunk" ]] && cp "$1" "$1.pre-cyberpunk" && echo "   backed up $1 -> $1.pre-cyberpunk"
  return 0
}

echo "== 1/5 dependencies (Homebrew)"
if ! command -v brew >/dev/null; then
  echo "Homebrew is required. Install it from https://brew.sh then re-run ./install.sh" >&2
  exit 1
fi
[[ -d /Applications/Ghostty.app ]] || brew install --cask ghostty
if ! ls ~/Library/Fonts /Library/Fonts 2>/dev/null | grep -qi "FiraCodeNerdFont"; then
  brew install --cask font-fira-code-nerd-font
fi
command -v starship >/dev/null || brew install starship
command -v eza >/dev/null || echo "   (optional: 'brew install eza' for richer ls colors — falls back to built-in ls without it)"

echo "== 2/5 config files -> ~/.config/ghostty and ~/.config/starship.toml"
mkdir -p "$GC/shaders" "$GC/icons"
backup_once "$GC/config"
backup_once "$GC/cyberpunk.zsh"
backup_once "$HOME/.config/starship.toml"
cp "$HERE/config"                "$GC/config"
cp "$HERE/shaders/cyberpunk.glsl" "$GC/shaders/cyberpunk.glsl"
cp "$HERE/cyberpunk.zsh"         "$GC/cyberpunk.zsh"
cp "$HERE/apply-icon.sh"         "$GC/apply-icon.sh"
cp "$HERE"/icons/*.png           "$GC/icons/"
cp "$HERE/starship.toml"         "$HOME/.config/starship.toml"
chmod +x "$GC/apply-icon.sh"

echo "== 3/5 write the absolute icon path into the config"
# Ghostty's macos-custom-icon does not expand ~, so it must be your real home dir.
sed -i '' "s|__HOME__|$HOME|" "$GC/config"

echo "== 4/5 ~/.zshrc (each line added only if missing)"
touch ~/.zshrc
grep -qF 'starship init zsh' ~/.zshrc        || echo 'eval "$(starship init zsh)"' >> ~/.zshrc
grep -qF 'ZLE_RPROMPT_INDENT' ~/.zshrc       || echo 'export ZLE_RPROMPT_INDENT=0' >> ~/.zshrc
grep -qF 'ghostty/cyberpunk.zsh' ~/.zshrc    || echo 'source ~/.config/ghostty/cyberpunk.zsh' >> ~/.zshrc

echo "== 5/5 apply the app icon (relaunches Ghostty + Dock)"
"$GC/apply-icon.sh" "$GC/icons/Mono.png"

echo ""
echo ">> DONE. Open a new Ghostty window to jack in."
echo ">> Swap icons anytime: ~/.config/ghostty/apply-icon.sh Window.png   (or Hazard.png)"
