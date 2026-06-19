# termclip

> Faithful PNG screenshots of an interactive terminal / TUI — in **both dark and light themes**.

`termclip` drives a **persistent `tmux` session** so you (or an AI agent) can launch a
command, type text, send keys, and **snapshot the rendered screen on demand**. Each
snapshot is replayed through [VHS](https://github.com/charmbracelet/vhs) under a *real*
terminal theme, so colors, bold/italic/underline, 256‑color, truecolor, and box‑drawing
are reproduced exactly — and the **same screen** is rendered under a dark *and* a light
palette (default foreground/background and the 16 ANSI colors flip correctly per theme).

<table>
  <tr>
    <td align="center"><b>Dark</b></td>
    <td align="center"><b>Light</b></td>
  </tr>
  <tr>
    <td><img src="examples/ov-menu.dark.png" alt="ov config — dark" width="460"></td>
    <td><img src="examples/ov-menu.light.png" alt="ov config — light" width="460"></td>
  </tr>
</table>

<sub>The same `ov config` TUI screen, captured once and rendered in both themes. Note the
truecolor wordmark stays constant while the default text and 16‑color palette flip per theme.</sub>

## Why

An AI agent working in a loop often needs to **see** what a terminal program looks like —
not just its text, but the *rendered* screen: highlighted menu rows, colored status, tables,
selection state. Plain `tmux capture-pane` gives text; static ANSI→image converters use a
fixed palette and can't produce a faithful **light** theme (default‑fg text goes invisible).

termclip solves both: it keeps an **interactive, persistent terminal** you can drive
step‑by‑step, and renders each snapshot through a real themed terminal so **dark and light
are both faithful**. Capture, look, type more, capture again.

## Install

Requirements: **`tmux`** and **`vhs`** (required); **ImageMagick** (`magick`/`convert`,
optional — used to trim the image to content).

```bash
# macOS
brew install tmux vhs imagemagick

# clone + put `termclip` on your PATH
git clone https://github.com/ZaynJarvis/termclip.git
cd termclip
./install.sh          # installs deps if missing, links `termclip`, installs the Claude skill
```

Or just run the script directly: `./skill/bin/termclip help`.

## Quickstart

### One‑shot — capture a command's opening screen
```bash
termclip shot --out hero --cols 100 --rows 40 --settle 3000 -- ov config
#   -> hero.dark.png   hero.light.png
```

### Live — drive the program and snapshot any screen
```bash
termclip start -s demo --cols 100 --rows 40 -- ov config   # launch in a persistent session
termclip snap  -s demo menu --settle 3000                  # snapshot the current screen
termclip key   -s demo Down Enter                          # navigate (arrow keys, Enter)
termclip snap  -s demo switch                              # snapshot the new screen
termclip key   -s demo Escape                              # back out safely
termclip stop  -s demo                                     # always stop when done
```

Every `snap`/`shot` prints the PNG paths it wrote — open them, or (for an agent) read them.

<table>
  <tr>
    <td><img src="examples/ov-switch.dark.png" alt="Switch screen — dark" width="460"></td>
    <td><img src="examples/ov-switch.light.png" alt="Switch screen — light" width="460"></td>
  </tr>
</table>

<sub>A different screen reached by sending <code>Down Enter</code> to the live session — the
<code>[Active]</code> tag and highlighted selection are preserved in both themes.</sub>

## Command reference

| Command | Description |
|---|---|
| `start -s NAME [--cols N] [--rows N] -- <cmd...>` | Launch `<cmd>` in a persistent, fixed‑size session |
| `type -s NAME "<text>"` | Type literal text into the session (no Enter) |
| `key -s NAME <Key>...` | Send keys (`Enter Up Down Left Right Escape Tab Space C-c BSpace F1`…) |
| `snap -s NAME [PREFIX] [--theme dark\|light\|both] [--settle MS]` | Snapshot the current screen → PNG(s) |
| `shot --out PREFIX [--cols N --rows N --settle MS] -- <cmd...>` | `start → settle → snap both → stop`, in one call |
| `render <file.ans> [--out PREFIX] [--theme ...] [--cols N --rows N]` | Render a raw `tmux capture-pane -e` dump to PNG(s) |
| `ls` | List active sessions |
| `stop -s NAME` · `stop --all` | Kill a session / kill everything and clean state |
| `help` | Show usage |

### Key options
- **`--settle MS`** — wait before capturing, so a slow/animated TUI finishes drawing
  (use ~3000ms for a program's first screen if it probes a server).
- **`--cols` / `--rows`** — terminal geometry. Tall TUIs need more rows; the capture shows
  exactly what a terminal that size would show.
- **`--theme dark|light|both`** — which theme(s) to render (default `both`).

## Themes

Defaults: `Catppuccin Mocha` (dark) and `Catppuccin Latte` (light). Override with any
theme from `vhs themes`:

```bash
TERMCLIP_DARK_THEME="Dracula" TERMCLIP_LIGHT_THEME="Github" \
  termclip shot --out demo -- some-tui
```

## How it works

```
 tmux (-L termclip)            per snapshot
 ┌────────────────┐     capture-pane -p -e          VHS replay (dark theme)  ─► PREFIX.dark.png
 │ your program,  │ ──►  one ANSI grid        ──►    VHS replay (light theme) ─► PREFIX.light.png
 │ driven by keys │                                  then  magick -trim
 └────────────────┘
```

A detached tmux session (on its own socket, so it never touches your tmux) holds the live
program. Each snapshot grabs the visible grid *with* ANSI escapes, then replays it inside a
headless VHS terminal under a real theme and screenshots it. Because VHS applies a full
palette, both the **default fg/bg flip** and the **16‑color remap** happen per theme, while
truecolor stays absolute. Full internals, env vars, and troubleshooting in
[`skill/reference.md`](skill/reference.md).

## Use as a Claude Code / AI agent skill

This repo *is* a [Claude Code skill](https://docs.claude.com/en/docs/claude-code/skills).
Install it so an agent can take terminal screenshots inside its loop:

```bash
./install.sh
# or manually:
cp -r skill ~/.claude/skills/termclip
```

The agent then captures a screen, **reads the PNG to see it**, sends more keys, and captures
again — closing the loop between "type something" and "see how the terminal looks".

## Requirements

- `tmux` ≥ 3.2 (truecolor / `terminal-features`)
- `vhs` (pulls in `ttyd` + `ffmpeg`)
- `imagemagick` *(optional, for trimming)*
- `bash`, `perl` *(present by default on macOS/Linux)*

## License

MIT — see [LICENSE](LICENSE).
