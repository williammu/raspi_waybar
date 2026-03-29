#!/bin/bash
# 树莓派 GPU 使用率图表（基于 v3d gpu_stats）
# 固定输出长度：13字符 "GPU: xxx% ████"

HISTORY_FILE="/tmp/gpu_history"
MAX_POINTS=4

# 图表字符
chars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

# 从 v3d gpu_stats 计算 GPU 使用率
get_gpu_usage() {
    local stats_file="/sys/devices/platform/v3dbus/fec00000.v3d/gpu_stats"
    
    if [ -r "$stats_file" ]; then
        local render_time=$(awk '/^render/ {print $4}' "$stats_file")
        
        if [ -n "$render_time" ]; then
            local prev_file="/tmp/gpu_prev"
            local prev_render=0
            local prev_time=$(date +%s%N)
            
            if [ -f "$prev_file" ]; then
                read prev_render prev_time < "$prev_file"
            fi
            
            local curr_time=$(date +%s%N)
            echo "$render_time $curr_time" > "$prev_file"
            
            if [ "$prev_render" -gt 0 ]; then
                local render_diff=$((render_time - prev_render))
                local time_diff=$((curr_time - prev_time))
                
                if [ "$time_diff" -gt 0 ]; then
                    local usage=$((render_diff * 100 / time_diff))
                    [ "$usage" -gt 100 ] && usage=100
                    [ "$usage" -lt 0 ] && usage=0
                    echo "$usage"
                    return
                fi
            fi
        fi
    fi
    
    echo "0"
}

# 获取当前值
current=$(get_gpu_usage)

# 读取历史
touch "$HISTORY_FILE"
history=$(cat "$HISTORY_FILE" 2>/dev/null)

# 添加新值
history="$history $current"

# 只保留最近 MAX_POINTS 个
history=$(echo "$history" | awk '{for(i=1; i<=NF; i++) print $i}' | tail -n "$MAX_POINTS" | tr '\n' ' ' | sed 's/ $//')

# 保存历史
echo "$history" > "$HISTORY_FILE"

# 生成图表（固定4个方块字符）
graph=""
count=0
for val in $history; do
    [ $count -ge 4 ] && break
    idx=$((val * 7 / 100))
    [ "$idx" -gt 7 ] && idx=7
    [ "$idx" -lt 0 ] && idx=0
    graph="$graph${chars[$idx]}"
    ((count++))
done

# 填充到4个字符
while [ ${#graph} -lt 4 ]; do
    graph="${graph}▁"
done

# 固定格式：13字符 "GPU: xxx% ████"
printf "GPU:%3d%% %s\n" "$current" "$graph"
