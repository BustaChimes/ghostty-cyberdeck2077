# cyberpunk.zsh — text "decode" reveal for the terminal
# Usage:  decode "ACCESS GRANTED"        (any text, ~0.3-0.4s regardless of length)
#         DECODE_BANNER=0 in your env disables the banner on new windows
#         DECODE_COLOR=$'\e[...m' decode "TEXT" overrides the final/locked color (default yellow)

zmodload zsh/zselect 2>/dev/null

decode() {
  emulate -L zsh
  local text="$*"
  [[ -z $text ]] && return
  local -a g=('▓' '▒' '░' '#' '%' '&' '@' '$' '0' '1' '7' 'X' 'Z' 'K' '/' '\' '<' '>' '=' '+')
  local Y=$'\e[38;2;252;238;10m' C=$'\e[38;2;0;240;255m' M=$'\e[38;2;255;46;151m' R=$'\e[0m'
  local F=${DECODE_COLOR:-$Y}
  local n=${#text} i j f out ch
  local frames=2
  local step=$(( (n + 24) / 25 ))          # lock more chars per frame on long lines
  local tick=$(( 50 * step / (n * frames) )); (( tick < 1 )) && tick=1
  printf '\e[?25l'
  for (( i=0; i<=n; i+=step )); do
    for (( f=0; f<frames; f++ )); do
      out="${F}${text[1,i]}"
      for (( j=i+1; j<=n; j++ )); do
        ch="${text[j]}"
        if [[ $ch == ' ' ]]; then
          out+=' '
        else
          (( RANDOM % 2 )) && out+="$C" || out+="$M"
          out+="${g[RANDOM % $#g + 1]}"
        fi
      done
      printf '\r%s%s' "$out" "$R"
      if (( $+functions[zselect] || $+builtins[zselect] )); then zselect -t $tick; else sleep 0.01; fi
    done
  done
  printf '\r%s%s%s\n\e[?25h' "$F" "$text" "$R"
}

# ---- banner on new Ghostty windows ----
if [[ -o interactive && $TERM_PROGRAM == ghostty && ${DECODE_BANNER:-1} == 1 && -z $_CP_BANNER_DONE ]]; then
  export _CP_BANNER_DONE=1
  typeset -a _lines=(
    "// LINK ESTABLISHED :: ${(U)HOST%%.*} :: $(date +%H:%M)"
    "// ACCESS GRANTED :: NODE ${(U)HOST%%.*}"
    "// UPLINK SYNCED :: TRACE CLEAN"
    "// SESSION OPEN :: ${(U)HOST%%.*} :: $(date +%a\ %d\ %b)"
  )
  decode "${_lines[RANDOM % $#_lines + 1]}"
  unset _lines
fi

# ---- themed ls colors ----
# ANSI codes so colors come from the Ghostty palette (config): 33=yellow #fcee0a,
# 36=cyan #00f0ff, 35=magenta #ff2e97, 31=red #ff003c, 32=green #00ff9c, 34=blue #00b0ff.
# dirs yellow · symlinks cyan · executables green · media magenta · archives red · docs blue
_cp_ls='di=1;33:ln=36:or=1;31:mi=31:ex=1;32:so=35:pi=33:bd=33:cd=33:su=1;32:sg=1;32:tw=1;33:ow=1;33'
_cp_ls+=':*.zip=31:*.tar=31:*.gz=31:*.tgz=31:*.bz2=31:*.xz=31:*.7z=31:*.rar=31:*.dmg=31'
_cp_ls+=':*.png=35:*.jpg=35:*.jpeg=35:*.gif=35:*.webp=35:*.svg=35:*.ico=35:*.icns=35'
_cp_ls+=':*.mp4=35:*.mov=35:*.mkv=35:*.webm=35:*.mp3=35:*.wav=35:*.flac=35:*.aac=35:*.ogg=35'
_cp_ls+=':*.pdf=34:*.md=34:*.json=34:*.toml=34:*.yaml=34:*.yml=34:*.glsl=34'
export LS_COLORS=$_cp_ls                 # zsh completion + GNU tools
if command -v eza >/dev/null; then
  export EZA_COLORS="$_cp_ls:da=34:sn=36:sb=36:uu=37:gu=37"
  alias ls='eza'
else
  export CLICOLOR=1                      # BSD/macOS ls
  export LSCOLORS='DxGxFxdxCxDxDxCxCxDxDx'   # same scheme, 16-color (maps to palette)
fi
unset _cp_ls

# ---- decode-styled command wrapper ----
# Usage: cprun <command> [args...]      e.g. cprun make -j8
cprun() {
  emulate -L zsh
  zmodload zsh/datetime 2>/dev/null
  if (( $# == 0 )); then
    print -ru2 -- 'usage: cprun <command> [args...]'
    return 64
  fi
  local start dur code
  DECODE_COLOR=$'\e[2;38;2;0;240;255m' decode "// EXECUTING :: $*"
  start=$EPOCHREALTIME
  "$@"
  code=$status
  printf -v dur '%.1fs' $(( EPOCHREALTIME - start ))
  if (( code == 0 )); then
    DECODE_COLOR=$'\e[38;2;0;255;156m' decode "// COMPLETE :: 0 :: $dur"
  else
    DECODE_COLOR=$'\e[38;2;255;0;60m' decode "// FAILED :: $code :: $dur"
  fi
  return $code
}

# ---- ssh TERM fix ----
# Remote hosts usually lack the xterm-ghostty terminfo ("unknown terminal type").
# Advertise a universal TERM to the remote only; local TERM stays xterm-ghostty
# (the inline assignment scopes TERM to this one ssh invocation).
ssh() { TERM=xterm-256color command ssh "$@" }
