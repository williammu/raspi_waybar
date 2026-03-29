#!/bin/bash
# 合并内存信息和 TOP3 内存进程
# 格式: MEM 4G/8G 54%    proc1:123M proc2:45M proc3:12M
# 固定输出长度：60字符

# 获取内存信息
mem_total_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
mem_avail_kb=$(grep MemAvailable /proc/meminfo 2>/dev/null | awk '{print $2}')

if [ -z "$mem_total_kb" ] || [ "$mem_total_kb" -eq 0 ]; then
    printf "%-60s" "MEM n/a"
    exit 0
fi

# 转换为 GB
total_gb=$((mem_total_kb / 1024 / 1024))
used_kb=$((mem_total_kb - mem_avail_kb))
used_gb=$((used_kb / 1024 / 1024))

# 计算百分比
percentage=$((used_kb * 100 / mem_total_kb))

# 构建内存摘要部分
mem_summary=$(printf "MEM %dG/%dG %d%%" "$used_gb" "$total_gb" "$percentage")

# 获取 TOP3 内存进程
processes=$(ps -eo rss,comm --sort=-rss 2>/dev/null | tail -n +2 | \
grep -v -E "ps|topcpu|topmem|mem_combined|awk|bash" | \
awk -v count=3 '
    BEGIN { n=0; out="" }
    {
        rss = $1
        cmd = $2
        mb = int(rss / 1024)
        if (mb < 1) mb = 1
        # 进程名最多8字符
        if (length(cmd) > 8) cmd = substr(cmd, 1, 8)
        # 格式：名字:数值M␣
        item = cmd ":" mb "M "
        out = out item
        if (++n >= count) exit
    }
    END { 
        gsub(/ $/, "", out)
        if (out == "") out = "n/a"
        print out
    }')

# 合并输出：内存摘要 + 正好4个空格 + 进程信息
result="${mem_summary}    ${processes}"

# 截断或填充到正好60字符
len=${#result}
if [ $len -gt 60 ]; then
    result="${result:0:60}"
elif [ $len -lt 60 ]; then
    # 在末尾填充空格
    padding=$((60 - len))
    for i in $(seq 1 $padding); do
        result="${result} "
    done
fi

echo "$result"
