#!/usr/bin/env bash
# termclip installer — installs dependencies, links the `termclip` CLI onto your
# PATH, and installs the Claude Code skill. Idempotent; safe to re-run.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$REPO/skill"
BIN_SRC="$SKILL_SRC/bin/termclip"

say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!!\033[0m %s\n'  "$*" >&2; }

# 1) dependencies -----------------------------------------------------------
need=(); for d in tmux vhs; do command -v "$d" >/dev/null 2>&1 || need+=("$d"); done
command -v magick >/dev/null 2>&1 || command -v convert >/dev/null 2>&1 || need+=(imagemagick)
if [ "${#need[@]}" -gt 0 ]; then
  if command -v brew >/dev/null 2>&1; then
    say "installing missing dependencies: ${need[*]}"
    brew install "${need[@]}"
  else
    warn "missing dependencies: ${need[*]} — install them, e.g.:"
    warn "    brew install ${need[*]}        # macOS"
    warn "    (vhs also needs ttyd + ffmpeg)"
  fi
else
  say "dependencies present (tmux, vhs, imagemagick)"
fi

# 2) link the CLI onto PATH --------------------------------------------------
chmod +x "$BIN_SRC"
BIN_DIR=""
for d in "$HOME/.local/bin" "/usr/local/bin" "/opt/homebrew/bin"; do
  if [ -d "$d" ] && [ -w "$d" ]; then BIN_DIR="$d"; break; fi
done
[ -z "$BIN_DIR" ] && { BIN_DIR="$HOME/.local/bin"; mkdir -p "$BIN_DIR"; }
ln -sf "$BIN_SRC" "$BIN_DIR/termclip"
say "linked CLI: $BIN_DIR/termclip -> $BIN_SRC"
case ":$PATH:" in *":$BIN_DIR:"*) ;; *) warn "add $BIN_DIR to your PATH to use \`termclip\` directly";; esac

# 3) install the Claude Code skill ------------------------------------------
SKILL_DST="$HOME/.claude/skills/termclip"
if [ -d "$HOME/.claude/skills" ] || mkdir -p "$HOME/.claude/skills" 2>/dev/null; then
  rm -rf "$SKILL_DST" 2>/dev/null || true
  ln -sf "$SKILL_SRC" "$SKILL_DST"
  say "installed Claude skill: $SKILL_DST -> $SKILL_SRC"
else
  warn "could not create ~/.claude/skills — copy 'skill/' there manually to install the skill"
fi

say "done. Try:  termclip shot --out demo -- <your-command>"
