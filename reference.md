# termclip — reference

Internals, every knob, and troubleshooting. For day‑to‑day usage see `SKILL.md`.

## How it works

```
 ┌── live, persistent ──┐      ┌──────── per snapshot ─────────┐
 │  tmux  (-L termclip) │      │  capture-pane -p -e            │   one ANSI grid
 │  your program runs   │ ───► │      │                        │   ↓ rendered twice
 │  here; you send keys │      │      ▼                        │
 └──────────────────────┘      │  VHS replay  (dark theme)  ─► PREFIX.dark.png
                               │  VHS replay  (light theme) ─► PREFIX.light.png
                               │      │                        │
                               │      ▼  magick -trim          │
                               └───────────────────────────────┘
```

1. **Persistence.** `start` creates a *detached* `tmux` session on an isolated server
   socket (`tmux -L termclip`) so it never collides with your own tmux. The session is
   created at a fixed size (`--cols`×`--rows`) with `status off`, `COLORTERM=truecolor`,
   and truecolor terminal features, so the captured output keeps full color.
2. **Interaction.** `type` sends literal text (`tmux send-keys -l`); `key` sends named
   keys (`tmux send-keys Down Enter …`). The program redraws in the live pane.
3. **Capture.** `snap` waits `--settle` ms (so the program finishes redrawing), then
   `tmux capture-pane -p -e` dumps the visible grid *with* SGR escapes. A per‑line
   reset (`\e[0m`) is appended to prevent color bleeding between rows.
4. **Themed render.** The captured grid is replayed inside a headless VHS terminal —
   `clear; cat grid.ans` under a real **theme** — and screenshotted. Running it under a
   dark theme and a light theme produces the two PNGs. Because VHS applies a full
   terminal palette, the **default foreground/background flip** and the **16 ANSI
   colors are remapped** per theme (truecolor stays absolute, which is correct).
5. **Trim.** `magick -trim` crops the render down to the content (the canvas is
   intentionally oversized for reliability, then trimmed).

### Why replay instead of a static ANSI→image converter?
Tools like `freeze` render ANSI to PNG but use a *fixed* palette and have no
default‑foreground control, so a light theme leaves default‑fg text near‑invisible and
the 16 colors don't change. Replaying through a real themed terminal (VHS) is the only
approach that faithfully **re‑themes** a captured screen for both light and dark.

## Environment variables

| Variable | Default | Meaning |
|---|---|---|
| `TERMCLIP_DARK_THEME` | `Catppuccin Mocha` | dark render theme (any `vhs themes` name) |
| `TERMCLIP_LIGHT_THEME` | `Catppuccin Latte` | light render theme |
| `TERMCLIP_FONT_SIZE` | `22` | render font size (px) |
| `TERMCLIP_FONT_FAMILY` | _(VHS default: JetBrains Mono)_ | render font |
| `TERMCLIP_PADDING` | `24` | padding around the terminal in the render |
| `TERMCLIP_COLS` / `TERMCLIP_ROWS` | `100` / `30` | default session geometry |
| `TERMCLIP_SETTLE_MS` | `500` | default wait before a capture |
| `TERMCLIP_OUT` | `.` | output directory for `snap`/`shot` PNGs |
| `TERMCLIP_SOCKET` | `termclip` | tmux server socket name (`-L`) |
| `TERMCLIP_HOME` | `${TMPDIR:-/tmp}/termclip` | per‑session state dir (`/tmp/termclip` if `TMPDIR` is unset, e.g. Linux) |

Per‑call flags (`--cols`, `--rows`, `--theme`, `--settle`, `--out`) override the env.

## Themes
List everything VHS supports:
```bash
vhs themes
```
Good light themes: `Catppuccin Latte`, `Github`, `Builtin Solarized Light`,
`rose-pine-dawn`, `tokyonight-day`, `OneHalfLight`.
Good dark themes: `Catppuccin Mocha`, `Dracula`, `nord`, `TokyoNight`,
`GruvboxDark`, `OneDark`, `Builtin Solarized Dark`.

```bash
TERMCLIP_DARK_THEME="Dracula" TERMCLIP_LIGHT_THEME="Github" \
  termclip shot --out demo -- some-tui
```

## Sending keys (tmux key names)
`key` passes its arguments straight to `tmux send-keys`, so any tmux key name works:
`Enter Escape Tab Space BSpace Up Down Left Right Home End PgUp PgDn`
`C-c` (Ctrl‑C) `C-d` `M-x` (Alt‑x) `F1`…`F12`. Examples:
```bash
termclip key -s s Down Down Enter      # move down twice, select
termclip key -s s C-c                  # Ctrl-C
termclip type -s s "hello world"       # literal text, then:
termclip key -s s Enter
```

## Capturing tall / wide screens
The capture reflects a terminal of exactly `--cols`×`--rows`. If a TUI's header or list
is taller than the rows, increase `--rows` (e.g. `--rows 45`). Width rarely needs
changing; `--cols 120` for very wide tables.

## Safety in destructive TUIs
termclip just relays keys — it has no idea which screens mutate state. When screenshotting
a config/installer/delete flow: navigate with arrows, **back out with `Escape` or `C-c`**,
and never send `Enter` on a "Save"/"Delete"/"Yes" confirmation unless you mean it.

## Troubleshooting

- **`render produced no PNG`** — VHS's headless screenshot is timing‑flaky; termclip
  already retries 4× with an oversized canvas. If it still fails, the theme name is
  probably invalid — check `vhs themes`.
- **Colors look wrong / washed out** — the source program may emit truecolor that is
  theme‑independent by design; that's expected (truecolor doesn't flip with the theme).
- **Blank or partial capture** — increase `--settle` (the program hadn't finished drawing).
- **Right edge of wide lines cut** — increase `--cols` on `start`/`shot`.
- **A stray block where the cursor would be** — fixed in the renderer (cursor is hidden
  and no shell prompt is shown); if you see one, you're on an old build.
- **Leftover sessions** — `termclip ls` to inspect, `termclip stop --all` to clean up.
- **Nested tmux** — fine; termclip uses its own socket, so it won't disturb your session.

## Files & state
- Sessions live on the `tmux -L termclip` server (separate from your tmux).
- Per‑session state (geometry, last capture) is under `${TMPDIR:-/tmp}/termclip/<name>/`.
- `stop` removes the session and its state; `stop --all` kills the whole server.
