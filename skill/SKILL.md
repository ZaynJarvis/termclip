---
name: termclip
description: Capture faithful PNG screenshots of an interactive terminal or TUI in BOTH dark and light themes. Drives a persistent tmux session so you can launch a command, type text, send keys (arrows/Enter/Esc), and snapshot the rendered screen — then Read the PNGs to actually SEE the real colors, layout, menus, and highlighted selection. Use when you need to see how a CLI or TUI looks, verify a terminal UI renders correctly, document a tool's screens, capture light+dark theme variants, or check what a command looks like as you type into it.
---

# termclip

Take **pixel-faithful screenshots** of a terminal program — including full‑screen
TUIs — in **dark and light** themes. You drive a live, persistent `tmux` session
(launch a command, type, send keys, snapshot on demand); each snapshot is replayed
through **VHS** under a real terminal theme, so colors, bold/italic/underline,
256‑color, truecolor, and box‑drawing are reproduced exactly, and the *same* screen
is rendered under both a dark and a light palette (default fg/bg and the 16 ANSI
colors flip correctly per theme).

The script is bundled at **`bin/termclip`** next to this file. Call it by its
absolute path (e.g. `"$SKILL_DIR/bin/termclip"`), or just `termclip` if it's on PATH.

## When to use
- You need to **see** how a CLI/TUI looks (menus, tables, highlighted rows, status).
- Verify a terminal UI renders correctly / didn't break.
- Capture **light + dark** variants of a screen for docs or a README.
- Inspect what a command's output looks like as you type into it.

## Two ways to use it

### A. Live (interactive) — drive the program, snapshot any screen
Best when you don't know the screens ahead of time and want to navigate reactively.

```bash
termclip start -s demo --cols 100 --rows 40 -- ov config   # launch in a persistent session
termclip snap  -s demo menu --settle 3000                  # snapshot current screen (waits 3s first)
#   -> ./menu.dark.png  ./menu.light.png        (Read these to see the result)

termclip key   -s demo Down Enter                          # navigate (send keys)
termclip type  -s demo "my-name"                           # type literal text (no Enter)
termclip key   -s demo Enter                               # press Enter
termclip snap  -s demo step2                               # snapshot the new screen

termclip key   -s demo Escape                              # back out safely (don't confirm destructive prompts)
termclip stop  -s demo                                     # ALWAYS stop when done
```

### B. One-shot — capture a command's opening screen
Best for a quick, deterministic single capture.

```bash
termclip shot --out hero --cols 100 --rows 40 --settle 3000 -- ov config
#   -> ./hero.dark.png  ./hero.light.png
```

After any `snap`/`shot`, **Read the printed `.dark.png` / `.light.png` paths** to see the result.

## Command reference
| Command | What it does |
|---|---|
| `start -s NAME [--cols N] [--rows N] -- <cmd...>` | Launch `<cmd>` in a persistent session of fixed size |
| `type -s NAME "<text>"` | Type literal text (no Enter) |
| `key  -s NAME <Key>...` | Send keys: `Enter Up Down Left Right Escape Tab Space C-c BSpace` etc. |
| `snap -s NAME [PREFIX] [--theme dark\|light\|both] [--settle MS]` | Snapshot current screen → PNG(s) |
| `shot --out PREFIX [--cols N --rows N --settle MS] -- <cmd...>` | start → settle → snap both → stop, in one call |
| `render <file.ans> [--out PREFIX] [--theme ...]` | Render a raw `tmux capture-pane -e` dump to PNG(s) |
| `ls` | List active sessions |
| `stop -s NAME` / `stop --all` | Kill a session / all sessions + clean state |

## Tips that matter
- **Sessions persist** until you `stop` them. Always `stop` (or `stop --all`) when finished.
- **`--settle MS`** is the wait *before* capturing — give slow/animated TUIs time to redraw
  (use ~3000ms for a program's first screen if it probes a server/network).
- **Geometry**: `--cols`/`--rows` set the terminal size. Tall TUIs need more rows (`--rows 40`);
  the capture shows exactly what a terminal of that size would show.
- **Sending keys**: named keys go through `key` (passed straight to `tmux send-keys`),
  literal text goes through `type`. Combine in any order.
- **Be careful in destructive TUIs**: navigate with arrows and back out with `Escape`/`C-c`;
  do **not** confirm save/delete prompts unless that's the intent.
- **Themes** default to `Catppuccin Mocha` (dark) / `Catppuccin Latte` (light). Override with
  `TERMCLIP_DARK_THEME` / `TERMCLIP_LIGHT_THEME` (any name from `vhs themes`).
- **Output dir** defaults to the current directory; set `TERMCLIP_OUT=some/dir`.

## Requirements
`tmux` and `vhs` (required); `imagemagick`'s `magick`/`convert` (optional, used to trim).
On macOS: `brew install tmux vhs imagemagick`. See `reference.md` for internals,
all env knobs, and troubleshooting.
