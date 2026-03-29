# Waybar 系统监控栏技术规格书

## 1. 概述

### 1.1 项目目标
构建一个基于 Waybar 的系统监控状态栏，实时显示 CPU、GPU、内存、磁盘、网络等系统信息，采用固定宽度布局确保所有模块在屏幕边界内正确显示。

### 1.2 运行环境
- **平台**: Linux (Wayland 桌面环境)
- **依赖**: waybar, bash, awk, ps, df, iw 等标准工具
- **硬件**: 树莓派 (v3d GPU 支持)

---

## 2. 架构设计

### 2.1 整体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                        Waybar 状态栏                             │
├─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────┤
│  CPU    │  Cores  │ TOP CPU │   GPU   │   WiFi  │  Load   │ Mem │
│ 图表    │ 4核图表 │ 进程TOP3│  图表   │ 信号+速度│  负载   │组合 │
├─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────┤
│                        自定义脚本模块                             │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 模块清单

| 模块ID | 名称 | 功能 | 刷新间隔 | 脚本路径 |
|--------|------|------|----------|----------|
| cpug | CPU总使用率 | CPU整体使用率+历史图表 | 1s | `scripts/cpu_graph.sh` |
| cores | 4核使用率 | 4个CPU核心各自的历史图表 | 1s | `scripts/cores_graph.sh` |
| topcpu | CPU TOP3 | CPU占用最高的3个进程+温度 | 2s | `scripts/topcpu.sh` |
| gpu | GPU使用率 | GPU使用率+历史图表 | 2s | `scripts/gpu.sh` |
| wifi | WiFi信息 | 信号强度+上下行速度 | 2s | `scripts/wifi_info.sh` |
| load | 系统负载 | 1分钟平均负载 | 5s | `scripts/load.sh` |
| mem_combined | 内存组合 | 内存使用率+TOP3内存进程 | 2s | `scripts/mem_combined.sh` |
| disk | 磁盘使用率 | 根分区使用率+总容量 | 10s | `scripts/disk.sh` |

---

## 3. 详细规格

### 3.1 布局规格

#### 3.1.1 屏幕适配
- **目标屏幕宽度**: 1920px
- **安全边距**: 40px (左右各20px)
- **可用宽度**: 1880px

#### 3.1.2 模块尺寸

| 模块 | min-width | padding | margin | 实际占用 | 输出字符数 |
|------|-----------|---------|--------|----------|------------|
| cpug | 110px | 0 4px | 4px 2px | 122px | 13 |
| cores | 240px | 0 4px | 4px 2px | 256px | 27 |
| topcpu | 320px | 0 4px | 4px 2px | 336px | 60 |
| gpu | 110px | 0 4px | 4px 2px | 122px | 13 |
| wifi | 130px | 0 4px | 4px 2px | 146px | 18 |
| load | 120px | 0 4px | 4px 2px | 136px | 10 |
| mem_combined | 400px | 0 4px | 4px 2px | 416px | 60 |
| disk | 100px | 0 2px | 4px 1px | 110px | ≤15 |

- **模块总占用**: 1544px
- **Waybar spacing**: 4px × 7 = 28px
- **总宽度**: 1572px < 1880px ✅

### 3.2 字体规格

#### 3.2.1 字体配置
```css
font-family: "DejaVu Sans Mono", "Liberation Mono", "FreeMono", "Noto Sans Mono CJK SC", monospace;
font-size: 13px;
font-weight: 600;
```

#### 3.2.2 字体选择原则
- 必须使用支持 Unicode 方块字符 (▁▂▃▄▅▆▇█) 的等宽字体
- 首选 DejaVu Sans Mono（完整支持 Unicode 方块字符）
- 避免使用比例字体显示图表字符，防止布局错位

### 3.3 颜色规格

| 模块 | 背景色 | 前景色 | 用途 |
|------|--------|--------|------|
| cpug | #7aa2f7 | #1a1b26 | CPU总览 |
| cores | #2ac3de | #1a1b26 | 核心详情 |
| topcpu | #ff9e64 | #1a1b26 | 进程监控 |
| gpu | #c0caf5 | #1a1b26 | GPU监控 |
| wifi | #e0af68 | #1a1b26 | 网络状态 |
| load | #73daca | #1a1b26 | 系统负载 |
| mem_combined | #9ece6a | #1a1b26 | 内存监控 |
| disk | #f7768e | #1a1b26 | 磁盘监控 |

---

## 4. 模块详细规格

### 4.1 CPU 总使用率 (cpug)

**输出格式**: `CPU: xxx% ████`
- 固定13字符
- 百分比右对齐3位
- 4个 Unicode 方块字符表示历史趋势

**图表字符**: `▁▂▃▄▅▆▇█` (8级)

**历史数据**: 保存最近4个采样点于 `/tmp/cpu_history`

### 4.2 4核使用率 (cores)

**输出格式**: `0:XXXX 1:XXXX 2:XXXX 3:XXXX`
- 固定27字符
- 每个核心显示4个历史方块字符
- 使用 `_` 作为最低级别字符

**历史数据**: 每个核心独立保存于 `/tmp/cpu_cores_history/core{0-3}`

### 4.3 CPU TOP3 (topcpu)

**输出格式**: `CPU xx°C: name1:xx.x% name2:xx.x% name3:xx.x%`
- 固定60字符（不足补空格，超出截断）
- 温度显示：从 `/sys/class/thermal/thermal_zone0/temp` 读取
- 进程名截断：最多12字符
- CPU百分比：保留1位小数

**过滤进程**: topcpu, topmem, ps, awk, bash

### 4.4 GPU 使用率 (gpu)

**输出格式**: `GPU: xxx% ████`
- 固定13字符
- 从 `/sys/devices/platform/v3dbus/fec00000.v3d/gpu_stats` 读取渲染时间计算
- 4个 Unicode 方块字符历史图表

**历史数据**: `/tmp/gpu_history`

### 4.5 WiFi 信息 (wifi)

**输出格式**: `📶xxx% ↓xxK↑xxK`
- 固定18字符
- 信号强度：0-100%，基于 dBm 转换
- 速度计算：300ms 采样差值，单位 KB/s
- 速度上限：99KB/s（显示限制）

### 4.6 系统负载 (load)

**输出格式**: `LOAD x.xx`
- 固定10字符
- 1分钟平均负载
- 从 `uptime` 命令解析

### 4.7 内存组合 (mem_combined)

**输出格式**: `MEM xG/xG xx%    name1:xxxM name2:xxxM name3:xxxM`
- 固定60字符
- 内存摘要：已用/总共 GB + 百分比
- TOP3进程：从 `/proc` 读取 RSS，转换为 MB
- 进程名截断：最多8字符

### 4.8 磁盘使用率 (disk)

**输出格式**: `DISK:xx% xxxG`
- 最多15字符
- 根分区使用率 + 总容量
- 超长时截断为 `...`

---

## 5. 测试规格

### 5.1 测试用例分类

| 类别 | 用例ID | 描述 |
|------|--------|------|
| 布局 | TC-001 ~ TC-002 | 屏幕宽度、总宽度约束 |
| 输出 | TC-003 | 各模块输出长度验证 |
| 功能 | TC-004 | 进程名截断验证 |
| 样式 | TC-005 ~ TC-007 | 固定宽度、边距、屏幕边界 |
| 适配 | TC-008 | 响应式调整验证 |

### 5.2 通过标准
1. 总宽度 ≤ 屏幕宽度 - 40px
2. 所有模块输出长度 ≤ CSS min-width 对应字符数
3. 进程名截断功能正常 (topcpu: 12字符, mem_combined: 8字符)
4. disk 模块完全可见
5. 边距均匀分布

---

## 6. 已知问题与解决方案

### 6.1 字体回退问题

**现象**: Unicode 方块字符与英文字符宽度不一致，导致布局错位。

**原因**: 字体回退机制导致方块字符使用比例字体 (Noto Sans CJK SC)。

**解决**: 使用 DejaVu Sans Mono 作为主字体，完整支持 Unicode 方块字符且等宽。

### 6.2 屏幕边界溢出

**现象**: disk 模块右侧超出屏幕边界。

**解决**: 减小 disk 模块宽度 (160px → 100px)，减小 padding 和 margin。

---

## 7. 配置文件

### 7.1 waybar 配置 (`config`)
- 所有模块置于 `modules-center`
- 高度：34px
- 模块间距：4px

### 7.2 样式配置 (`style.css`)
- 全局字体、颜色定义
- 各模块独立样式（背景色、宽度、边距）
- Tooltip 样式统一

---

## 8. 附录

### 8.1 文件清单

```
.
├── config              # waybar 主配置
├── style.css           # 样式配置
├── spec.md             # 本规格书
├── testcase.md         # 测试用例
├── FONT_ISSUE.md       # 字体问题记录
└── scripts/
    ├── cpu_graph.sh    # CPU总使用率
    ├── cores_graph.sh  # 4核使用率
    ├── topcpu.sh       # CPU TOP3
    ├── gpu.sh          # GPU使用率
    ├── wifi_info.sh    # WiFi信息
    ├── load.sh         # 系统负载
    ├── mem_combined.sh # 内存组合
    ├── disk.sh         # 磁盘使用率
    └── ...             # 调试脚本
```

### 8.2 调试工具

| 脚本 | 用途 |
|------|------|
| `debug_width.sh` | 显示各模块实际宽度 |
| `boundary_marker.sh` | 添加边界标记测试 |
| `cpu_graph_ascii.sh` | ASCII 字符替代方案 |
