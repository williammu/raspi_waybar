#!/bin/bash
# CPU 历史使用图表 - 使用方块字符
# 固定输出长度：13字符 "CPU: xxx% ████"

HISTORY_FILE="/tmp/cpu_history"
MAX_POINTS=4

# 计算 CPU 使用率
get_cpu() {
    grep "^cpu " /proc/stat | awk '{print ($2+$3+$4), ($2+$3+$4+$5)}'
}

read -r used1 total1 <<< $(get_cpu)
sleep 0.3
read -r used2 total2 <<< $(get_cpu)

if [ "$total2" -gt "$total1" ]; then
    current=$(( (used2 - used1) * 100 / (total2 - total1) ))
else
    current=0
fi

# 读取历史
touch "$HISTORY_FILE"
history=$(cat "$HISTORY_FILE" 2>/dev/null)

# 添加新值
history="$history $current"

# 只保留最近 MAX_POINTS 个
history=$(echo "$history" | awk '{for(i=1; i<=NF; i++) print $i}' | tail -n "$MAX_POINTS" | tr '\n' ' ' | sed 's/ $//')

# 保存历史
echo "$history" > "$HISTORY_FILE"

# 图表字符（从低到高）
chars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

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

# 固定格式：13字符 "CPU: xxx% ████"
printf "CPU:%3d%% %s\n" "$current" "$graph"
