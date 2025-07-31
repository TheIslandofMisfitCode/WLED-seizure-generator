#!/bin/bash

subnet="192.168.88"
timeout=1
interval=0.01
max_fx=117
hostfile="wled_hosts.txt"

start_fx_blast() {
  ip="$1"
  echo "[+] [$ip] FX machinegun online"

  while true; do
    fx=$((RANDOM % (max_fx + 1)))
    r=$((RANDOM % 256))
    g=$((RANDOM % 256))
    b=$((RANDOM % 256))
    bri=$((128 + RANDOM % 128))

    curl -s -X POST -H "Content-Type: application/json" \
      -d "{\"on\":true,\"bri\":$bri,\"seg\":[{\"fx\":$fx,\"col\":[[$r,$g,$b]]}]}" \
      "http://$ip/json/state" > /dev/null

    sleep $interval
  done
}

# -----------------------
# Scan if hostfile missing
# -----------------------
if [ ! -f "$hostfile" ]; then
  echo "[*] No $hostfile found. Scanning for WLEDs on $subnet.0/24..."
  > "$hostfile"
  for i in {1..254}; do
    ip="$subnet.$i"
    (
      info=$(curl -s --max-time $timeout "http://$ip/json/info")
      if echo "$info" | grep -q '"ver"' && echo "$info" | grep -q '"bootps"'; then
        echo "[✓] WLED found @ $ip"
        echo "$ip" >> "$hostfile"
      fi
    ) &
  done
  wait
fi

# -----------------------
# Load hostfile and fire
# -----------------------
mapfile -t wled_hosts < "$hostfile"

for ip in "${wled_hosts[@]}"; do
  start_fx_blast "$ip" &
done

wait
