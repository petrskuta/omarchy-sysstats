# AGENTS.md

Guide for coding agents changing this plugin. Human docs are in `README.md`.

## What this is

An Omarchy shell (Quickshell/QML) bar widget, plugin id `petrskuta.sysstats`.
The repo root is the plugin folder, installed at
`~/.config/omarchy/plugins/petrskuta.sysstats/`. That folder is a git clone
of `github.com/petrskuta/omarchy-sysstats`, so edit and commit there.

## Architecture

```
stats.sh 2  ──(one JSON line every 2s)──▶  Widget.qml  Process + SplitParser
                                           └─ apply(): parse, check, set root.stats
                                           └─ items: list of {icon code point, value}
                                           └─ Repeater draws icon + value Text pairs
```

JSON fields: `cpu`, `ram` (percent), `ramMb`, `ramTotalMb`, `gpu` (percent,
`-1` when unavailable), `down`, `up` (bytes/s), `powerUw` (microwatts, `-1`
when there is no battery), `battery` (the battery `status` string).

## Rules

- Never edit `/usr/share/omarchy/`. Read it for reference only:
  `$OMARCHY_PATH/shell/Ui/` holds the components and
  `$OMARCHY_PATH/shell/plugins/bar/widgets/` holds simple example widgets.
- Every `Text` uses `textFormat: Text.PlainText`. The shell is unsandboxed and
  long-lived, and data comes from a subprocess.
- Keep `apply()` defensive: cap the line length, wrap `JSON.parse` in try/catch,
  and check the types.
- Use `bar.fontFamily`, `Style.font.body`, `Style.bar.iconFont` and
  `bar.barForeground`, so the widget follows the theme. Never hardcode colours.
- Read sysfs and procfs only, with no root and no extra packages. A metric
  whose source is missing reports `-1` and is hidden in `items`.
- Icons are Nerd Font code points, rendered with `String.fromCodePoint`.
  Look them up at https://www.nerdfonts.com/cheat-sheet.
- The click runs `omarchy-launch-or-focus-tui btop`.

## Workflow

```bash
cd ~/.config/omarchy/plugins/petrskuta.sysstats
./stats.sh 1                           # check the data source; stop with Ctrl-C
omarchy plugin validate .              # check manifest.json against the schema
# Saving a file logs "Local plugin changed, reloading", but the running bar can
# keep the old code even after rescanPlugins. Restart the shell, then check the bar:
omarchy-restart-shell
journalctl --user --since "-1min" | grep -iE "sysstats|warn|error"   # QML errors
grim /tmp/full.png                     # screenshot of the active screen, to check visually
```

A `quickshell.qmlscanner ... outside of the config folder` warning is harmless
and appears for every user plugin.

Bump `version` in `manifest.json` for any change people would notice, then commit and push.

## Ideas not done yet

- AMD GPU via `/sys/class/drm/card*/device/gpu_busy_percent`.
- NVIDIA GPU via `nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits`.
- Settings in `shell.json`, such as the interval or which items to show, read through the bar widget config API.
- Colour a value when it crosses a threshold, for example CPU above 90%.
