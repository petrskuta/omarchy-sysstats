# System Stats for Omarchy

A minimal bar widget for the [Omarchy](https://omarchy.org/) shell: CPU, RAM, GPU,
network and power draw. It shows only icons and numbers, and you can click it to open btop.

```
 4%   36%   9%  ⇄ ↓7K ↑7K   21.3W
CPU   RAM   GPU   network     power
```

- **Click:** opens btop, or focuses it if it is already open.
- **Hover:** shows a tooltip with details (RAM in GB, charging versus drawing).
- Updates every 2 seconds, follows the bar's font and theme colours, and needs no root.

## Install

```bash
omarchy plugin add https://github.com/petrskuta/omarchy-sysstats.git --enable
```

Pick the `right` section when asked. To place it yourself:

```bash
omarchy bar move petrskuta.sysstats --section right --index 0
```

Update with `omarchy plugin update petrskuta.sysstats` and remove with
`omarchy plugin remove petrskuta.sysstats`.

## What the numbers mean

| Icon | Value | Source |
|------|-------|--------|
| CPU | Busy share of all cores | `/proc/stat` |
| RAM | Used share (total minus available) | `/proc/meminfo` |
| GPU | Busy share, hidden when unavailable | Intel `gt/gt0/rc6_residency_ms`: time not in RC6 idle |
| Network | Download and upload per second, all physical interfaces | `/proc/net/dev`, skipping `lo`, docker, veth, bridges |
| Power | Watts, hidden without a battery | `BAT*/power_now`, or `current_now × voltage_now` |

Two of these are estimates:

- **GPU** works on Intel GPUs that use the i915 driver. Iris Xe exposes no
  load percentage without root, so the widget estimates it from idle time.
  AMD and NVIDIA GPUs are not supported yet, and the GPU item is hidden for them.
- **Power** is read from the battery. On battery it is the whole laptop's draw.
  When plugged in it is the charging rate, and the icon becomes a plug.
  The true draw on AC would need root access to the RAPL energy counters.

## Files

| File | Purpose |
|------|---------|
| `manifest.json` | Plugin metadata: id `petrskuta.sysstats`, a bar widget, right section by default |
| `stats.sh` | Bash loop that prints one JSON line every N seconds |
| `Widget.qml` | Draws the icons and values, and handles the click and tooltip |

Saving any file under `~/.config/omarchy/plugins/petrskuta.sysstats/` hot-reloads the widget.
Icons are Nerd Font glyphs, given as code points in `Widget.qml`.

## License

MIT
