#!/usr/bin/env bash
vol_raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
vol=$(echo "$vol_raw" | awk '{printf "%d", $2*100}')
muted=0; echo "$vol_raw" | grep -q MUTED && muted=1
mic_raw=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)
mic=$(echo "$mic_raw" | awk '{printf "%d", $2*100}')
micm=0; echo "$mic_raw" | grep -q MUTED && micm=1
bri=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d %)
wifi=0; [ "$(nmcli radio wifi 2>/dev/null)" = "enabled" ] && wifi=1
bt=0; bluetoothctl show 2>/dev/null | grep -q "Powered: yes" && bt=1
bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1)
chg=0; cat /sys/class/power_supply/BAT*/status 2>/dev/null | grep -qi '^charging' && chg=1
read -r _ a1 b1 c1 d1 e1 f1 g1 _ < /proc/stat
sleep 0.25
read -r _ a2 b2 c2 d2 e2 f2 g2 _ < /proc/stat
t1=$((a1+b1+c1+d1+e1+f1+g1)); t2=$((a2+b2+c2+d2+e2+f2+g2))
i1=$((d1+e1)); i2=$((d2+e2))
dt=$((t2-t1)); cpu=0
[ "$dt" -gt 0 ] && cpu=$(( 100*(dt-(i2-i1))/dt ))
ram=$(free | awk '/Mem:/{printf "%d", $3/$2*100}')
disk=$(df / --output=pcent 2>/dev/null | tail -n1 | tr -dc 0-9)
night=0; pgrep -x hyprsunset >/dev/null && night=1
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$vol" "$muted" "$bri" "$wifi" "$bt" "$bat" "$chg" "$mic" "$micm" "$cpu" "$ram" "$disk" "$night"
