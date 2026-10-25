#!/bin/bash
# Prints one JSON line of system stats every INTERVAL seconds.
INTERVAL=${1:-2}

gpu=$(ls -d /sys/class/drm/card*/gt/gt0 2>/dev/null | head -1)
bat=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)

cpu_sample() { read -r _ u n s i w q sq st _ < /proc/stat; echo "$((u+n+s+i+w+q+sq+st)) $((i+w))"; }
net_sample() { awk 'NR>2 && $1 !~ /^(lo|docker|veth|br-|virbr)/ { rx+=$2; tx+=$10 } END { print rx+0, tx+0 }' /proc/net/dev; }
now_ms() { echo $(( $(date +%s%N) / 1000000 )); }

read -r ct0 ci0 < <(cpu_sample)
read -r rx0 tx0 < <(net_sample)
t0=$(now_ms)
rc0=$([ -n "$gpu" ] && cat "$gpu/rc6_residency_ms" || echo 0)

while sleep "$INTERVAL"; do
  read -r ct1 ci1 < <(cpu_sample)
  read -r rx1 tx1 < <(net_sample)
  t1=$(now_ms)
  dt=$((t1 - t0)); (( dt < 1 )) && dt=1

  dct=$((ct1 - ct0)); (( dct < 1 )) && dct=1
  cpu=$(( 100 * (dct - (ci1 - ci0)) / dct ))

  read -r mtotal mavail < <(awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{print t, a}' /proc/meminfo)
  ram=$(( 100 * (mtotal - mavail) / mtotal ))
  ramused=$(( (mtotal - mavail) / 1024 ))

  # GPU busy = share of wall time not spent in RC6 idle.
  gpupct=-1
  if [ -n "$gpu" ]; then
    rc1=$(cat "$gpu/rc6_residency_ms")
    gpupct=$(( 100 - 100 * (rc1 - rc0) / dt ))
    (( gpupct < 0 )) && gpupct=0; (( gpupct > 100 )) && gpupct=100
    rc0=$rc1
  fi

  down=$(( (rx1 - rx0) * 1000 / dt ))
  up=$(( (tx1 - tx0) * 1000 / dt ))

  watts=-1; status="Unknown"
  if [ -n "$bat" ]; then
    status=$(cat "$bat/status")
    if [ -r "$bat/power_now" ]; then
      watts=$(cat "$bat/power_now")
    elif [ -r "$bat/current_now" ]; then
      watts=$(( $(cat "$bat/current_now") * $(cat "$bat/voltage_now") / 1000000 ))
    fi
  fi

  printf '{"cpu":%d,"ram":%d,"ramMb":%d,"ramTotalMb":%d,"gpu":%d,"down":%d,"up":%d,"powerUw":%d,"battery":"%s"}\n' \
    "$cpu" "$ram" "$ramused" "$((mtotal / 1024))" "$gpupct" "$down" "$up" "$watts" "$status"

  ct0=$ct1; ci0=$ci1; rx0=$rx1; tx0=$tx1; t0=$t1
done
