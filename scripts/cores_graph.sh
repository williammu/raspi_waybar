#!/bin/bash
# 4个CPU核心的历史使用图表 - 并行计算
# 固定输出长度：24字符 "0:XXXX 1:XXXX 2:XXXX 3:XXXX"

HISTORY_DIR="/tmp/cpu_cores_history"
mkdir -p "$HISTORY_DIR"
MAX_POINTS=4
chars=("_" "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

# 一次性读取所有数据
for core in 0 1 2 3; do
    grep "^cpu$core " /proc/stat > "$HISTORY_DIR/s1_$core"
done

sleep 0.2

for core in 0 1 2 3; do
    grep "^cpu$core " /proc/stat > "$HISTORY_DIR/s2_$core"
done

# 计算单个核心
calc_core() {
    local core=$1
    local u1=$(awk '{print $2+$3+$4+$7+$8}' "$HISTORY_DIR/s1_$core")
    local t1=$(awk '{print $2+$3+$4+$5+$6+$7+$8}' "$HISTORY_DIR/s1_$core")
    local u2=$(awk '{print $2+$3+$4+$7+$8}' "$HISTORY_DIR/s2_$core")
    local t2=$(awk '{print $2+$3+$4+$5+$6+$7+$8}' "$HISTORY_DIR/s2_$core")
    
    if [ "$t2" -gt "$t1" ]; then
        echo $(( (u2-u1)*100/(t2-t1) ))
    else
        echo 0
    fi
}

# 更新图表
update_graph() {
    local core=$1
    local val=$2
    local hf="$HISTORY_DIR/core$core"
    
    local hist=$(cat "$hf" 2>/dev/null)
    hist="$hist $val"
    echo "$hist" | awk '{for(i=1; i<=NF; i++) print $i}' | tail -n "$MAX_POINTS" | tr '\n' ' ' | sed 's/ $//' > "$hf"
    
    local graph=""
    local count=0
    for v in $(cat "$hf"); do
        [ $count -ge 4 ] && break
        local i=$((v*8/100))
        [ "$i" -gt 8 ] && i=8
        graph="$graph${chars[$i]}"
        ((count++))
    done
    
    # 填充到4个字符
    while [ ${#graph} -lt 4 ]; do
        graph="${graph}_"
    done
    
    echo "$graph"
}

# 计算4个核心
c0=$(calc_core 0)
c1=$(calc_core 1)
c2=$(calc_core 2)
c3=$(calc_core 3)

# 清理临时文件
rm -f "$HISTORY_DIR"/s1_* "$HISTORY_DIR"/s2_*

# 输出固定24字符：0:XXXX 1:XXXX 2:XXXX 3:XXXX
g0=$(update_graph 0 $c0)
g1=$(update_graph 1 $c1)
g2=$(update_graph 2 $c2)
g3=$(update_graph 3 $c3)
printf "0:%s 1:%s 2:%s 3:%s\n" "$g0" "$g1" "$g2" "$g3"
