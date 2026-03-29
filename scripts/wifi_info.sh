#!/bin/bash
# WiFi 信号强度 + 上下行速度
# 固定输出长度：18字符 "📶xxx% ↓xxK↑xxK"

STATE_DIR="/tmp/waybar_wifi"
mkdir -p "$STATE_DIR"

# 获取WiFi接口（自动检测）
get_wifi_iface() {
    local iface=$(iw dev 2>/dev/null | grep -E "^\s+Interface" | awk '{print $2}' | head -1)
    if [ -z "$iface" ]; then
        iface="wlan0"
    fi
    echo "$iface"
}

# 获取信号强度
get_signal() {
    local iface=$(get_wifi_iface)
    local sig=""
    if command -v iw >/dev/null 2>&1; then
        sig=$(iw dev "$iface" link 2>/dev/null | grep "signal" | awk '{print $2}')
    elif [ -r /proc/net/wireless ]; then
        sig=$(awk "/$iface/ {print int(\$4)}" /proc/net/wireless 2>/dev/null)
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

# 格式化速度（自动选择单位）
format_speed() {
    local speed_kb=$1
    if [ "$speed_kb" -ge 1000 ]; then
        local speed_mb=$((speed_kb / 1024))
        [ "$speed_mb" -gt 99 ] && speed_mb=99
        printf "%2dM" "$speed_mb"
    else
        printf "%2dK" "$speed_kb"
    fi
}

# 获取上下行速度
get_speed() {
    local iface=$(get_wifi_iface)
    local stats_file="/sys/class/net/$iface/statistics"
    local state_file="$STATE_DIR/${iface}_stats"
    
    # 获取当前数据
    if [ -f "$stats_file/rx_bytes" ]; then
        local rx=$(cat "$stats_file/rx_bytes" 2>/dev/null)
        local tx=$(cat "$stats_file/tx_bytes" 2>/dev/null)
    else
        local rx=$(awk "/$iface:/ {print \$2}" /proc/net/dev 2>/dev/null)
        local tx=$(awk "/$iface:/ {print \$10}" /proc/net/dev 2>/dev/null)
    fi
    
    local now_ns=$(date +%s%N)
    
    if [ -f "$state_file" ]; then
        read -r prev_rx prev_tx prev_time_ns < "$state_file" 2>/dev/null
        
        if [ -n "$prev_rx" ] && [ -n "$prev_tx" ] && [ -n "$prev_time_ns" ]; then
            local time_diff_ms=$(( (now_ns - prev_time_ns) / 1000000 ))
            
            # 时间差至少500ms（waybar interval=1s，考虑执行时间）
            # 时间差不超过10秒（避免长时间休眠后异常值）
            if [ "$time_diff_ms" -ge 500 ] && [ "$time_diff_ms" -le 10000 ]; then
                local rx_diff=$((rx - prev_rx))
                local tx_diff=$((tx - prev_tx))
                
                [ "$rx_diff" -lt 0 ] && rx_diff=0
                [ "$tx_diff" -lt 0 ] && tx_diff=0
                
                # 计算 KB/s: bytes / (ms/1000) / 1024 = bytes * 1000 / ms / 1024
                local rx_speed=$((rx_diff * 1000 / time_diff_ms / 1024))
                local tx_speed=$((tx_diff * 1000 / time_diff_ms / 1024))
                
                # 低速时显示1K
                if [ "$rx_speed" -eq 0 ] && [ "$rx_diff" -gt 0 ]; then
                    rx_speed=1
                fi
                if [ "$tx_speed" -eq 0 ] && [ "$tx_diff" -gt 0 ]; then
                    tx_speed=1
                fi
                
                # 限制最大值
                [ "$rx_speed" -gt 9999 ] && rx_speed=9999
                [ "$tx_speed" -gt 9999 ] && tx_speed=9999
                
                local rx_str=$(format_speed "$rx_speed")
                local tx_str=$(format_speed "$tx_speed")
                
                echo "$rx $tx $now_ns" > "$state_file"
                printf "↓%s↑%s" "$rx_str" "$tx_str"
                return
            fi
        fi
    fi
    
    # 首次运行或无效数据
    echo "$rx $tx $now_ns" > "$state_file"
    echo "↓ 0K↑ 0K"
}

signal=$(get_signal)
speed=$(get_speed)
printf "📶%s%% %s\n" "$signal" "$speed"
