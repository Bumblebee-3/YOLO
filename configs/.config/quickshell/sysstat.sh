#!/bin/bash
# prints one line per second: "<cpu%> <mem%> <disk%> <down KB/s>"
prev_t=0; prev_i=0
iface=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
prev_rx=$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null || echo 0)

while :; do
  read -r _ u n s i io irq sirq st _ < /proc/stat
  t=$((u+n+s+i+io+irq+sirq+st)); idle=$((i+io))
  dt=$((t-prev_t)); di=$((idle-prev_i))
  if [ "$dt" -gt 0 ]; then cpu=$((100*(dt-di)/dt)); else cpu=0; fi
  prev_t=$t; prev_i=$idle

  mem=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "%d", 100*(t-a)/t}' /proc/meminfo)
  disk=$(df --output=pcent / | tail -1 | tr -dc '0-9')

  iface=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
  rx=$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null || echo 0)
  net=$(awk -v a="$rx" -v b="$prev_rx" 'BEGIN{d=(a-b)/1024; if(d<0)d=0; printf "%.1f", d}')
  prev_rx=$rx

  echo "$cpu $mem $disk $net"
  sleep 1
done
