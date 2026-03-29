#!/bin/bash
# 获取 CPU 占用最高的3个进程 + CPU 温度
# 格式: CPU xx°C: 进程名:CPU% 进程名:CPU% 进程名:CPU%
# 固定输出长度：正好60字符（填满320px模块）
# 进程名：最多12字符（3个进程）

sleep 0.5

# 获取 CPU 温度
get_temp() {
    local temp="N/A"
    if [ -r /sys/class/thermal/thermal_zone0/temp ]; then
        local t=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
        if [ -n "$t" ]; then
            if [ "$t" -gt 1000 ]; then
                temp=$((t / 1000))
            else
                temp=$t
            fi
        fi
    elif [ -r /sys/class/hwmon/hwmon0/temp1_input ]; then
        local t=$(cat /sys/class/hwmon/hwmon0/temp1_input 2>/dev/null)
        [ -n "$t" ] && temp=$((t / 1000))
    fi
    echo "$temp"
}

temp=$(get_temp)

# 构建前缀：CPU xx°C: （10字符）
prefix=$(printf "CPU %2s°C: " "$temp")

# 使用 ps 获取完整进程名和 CPU 使用率
ps -eo pid,pcpu,comm --sort=-pcpu 2>/dev/null | tail -n +2 | \
grep -v -E "topcpu|topmem|ps|awk|bash" | head -3 | awk -v prefix="$prefix" '
BEGIN { out = "" }
{
    pid = $1
    cpu = $2
    cmd = $3
    
    # 进程名最多12字符（3个进程）
    if (length(cmd) > 12) cmd = substr(cmd, 1, 12)
    
    # 格式：名字:CPU%␣
    item = cmd ":" cpu "% "
    out = out item
}
END {
    # 构建完整输出
    result = prefix out
    
    # 严格截断或填充到60字符
    len = length(result)
    if (len > 60) {
        result = substr(result, 1, 60)
    } else {
        while (length(result) < 60) {
            result = result " "
        }
    }
    print result
}'
