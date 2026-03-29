#!/bin/bash
# 获取磁盘使用率和总空间
# 格式: DISK:xx% 115G
# 固定输出长度：最多15字符

df -h / 2>/dev/null | tail -1 | awk '{
    size = $2
    usage = $5
    gsub(/%/, "", usage)
    out = "DISK:" usage "% " size
    # 限制长度，超出用...结尾
    if (length(out) > 15) out = substr(out, 1, 12) "..."
    print out
}'
