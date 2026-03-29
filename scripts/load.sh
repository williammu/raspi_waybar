#!/bin/bash
# 获取系统负载 (1分钟)
# 固定输出长度：10字符 "LOAD x.xx"

read -r l1 l2 l3 <<< $(uptime | awk -F'load average:' '{print $2}' | tr ',' ' ')
printf "LOAD %s\n" "$l1"
