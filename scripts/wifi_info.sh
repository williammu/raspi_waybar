#!/bin/bash
# WiFi 信号强度 + 上下行速度
# 固定输出长度：18字符 "📶xxx% ↓xxK↑xxK"

# 获取信号强度
get_signal() {
    local sig=""
    if command -v iw >/dev/null 2>&1; then
        sig=$(iw dev wlan0 link 2>/dev/null | grep "signal" | awk '{print $2}')
    elif [ -r /proc/net/wireless ]; then
        sig=$(awk '/wlan0/ {print int($4)}' /proc/net/wireless 2>/dev/null)
    fi
    
    if [ -n "$sig" ]; then
        if [ "$sig" -lt 0 ]; then
            local pct=$(( (sig + 90) * 100 / 60 ))
            [ "$pct" -gt 100 ] && pct=100
            [ "$pct" -lt 0 ] && pct=0
            printf "%3d" "$pct"
        else
            printf "%3d" "$sig"
        fi
    else
        echo "  0"
    fi
}

# 获取上下行速度
get_speed() {
    local iface="wlan0"
    local rx1=$(awk "/$iface:/ {print \$2}" /proc/net/dev 2>/dev/null)
    local tx1=$(awk "/$iface:/ {print \$10}" /proc/net/dev 2>/dev/null)
    
    sleep 0.3
    
    local rx2=$(awk "/$iface:/ {print \$2}" /proc/net/dev 2>/dev/null)
    local tx2=$(awk "/$iface:/ {print \$10}" /proc/net/dev 2>/dev/null)
    
    if [ -n "$rx2" ] && [ -n "$rx1" ]; then
        local rx_speed=$(( (rx2 - rx1) / 307 ))
        local tx_speed=$(( (tx2 - tx1) / 307 ))
        
        # 限制显示宽度为2字符
        [ "$rx_speed" -gt 99 ] && rx_speed=99
        [ "$tx_speed" -gt 99 ] && tx_speed=99
        
        printf "↓%2dK↑%2dK" "$rx_speed" "$tx_speed"
    else
        echo "↓ 0K↑ 0K"
    fi
}

signal=$(get_signal)
speed=$(get_speed)

# 固定格式：18字符 "📶xxx% ↓xxK↑xxK"
printf "📶%s%% %s\n" "$signal" "$speed"
