# Raspi Waybar

树莓派 Waybar 系统监控配置，实时显示 CPU、GPU、内存、磁盘、网络等系统信息。

![License](https://img.shields.io/badge/license-MIT-blue.svg)

## 功能特性

- **CPU 监控**: 总使用率图表 + 4核心独立图表 + TOP3 进程
- **GPU 监控**: 树莓派 v3d GPU 使用率图表
- **内存监控**: 使用率 + TOP3 内存进程
- **网络监控**: WiFi 信号强度 + 实时上下行速度
- **系统负载**: 1分钟平均负载
- **磁盘监控**: 根分区使用率

## 预览

```
┌─────────────────────────────────────────────────────────────────────────┐
│ CPU:  25% ▃▄▃▃ │ 0:▃▄▃▃ 1:▃▂▃▂ 2:▄▃▄▃ 3:▂▃▂▃ │ CPU 45°C: firefox:12.5% │
│ GPU:   5% ▁▁▁▃ │ 📶 85% ↓12K↑ 5K │ LOAD 0.45 │ MEM 2G/4G 50% │ DISK:35% 120G │
└─────────────────────────────────────────────────────────────────────────┘
```

## 安装

### 依赖

```bash
# Debian/Ubuntu/Raspberry Pi OS
sudo apt install waybar

# 字体（确保 Unicode 方块字符正常显示）
# 推荐: DejaVu Sans Mono, Liberation Mono
```

### 配置

```bash
# 克隆仓库
git clone git@github.com:williammu/raspi_waybar.git ~/.config/waybar

# 或手动复制文件到 ~/.config/waybar/
cp -r config style.css scripts ~/.config/waybar/
```

### 启动

```bash
# 手动启动
waybar

# 或添加到 sway/wayfire 等 compositor 的启动配置
```

## 文件结构

```
.
├── config              # Waybar 主配置
├── style.css           # 样式配置
├── README.md           # 本文件
├── spec.md             # 技术规格书
├── testcase.md         # 测试用例
├── FONT_ISSUE.md       # 字体问题解决方案
└── scripts/
    ├── cpu_graph.sh      # CPU 总使用率图表
    ├── cores_graph.sh    # 4核心使用率图表
    ├── topcpu.sh         # CPU TOP3 进程
    ├── gpu.sh            # GPU 使用率
    ├── wifi_info.sh      # WiFi 信号和速度
    ├── load.sh           # 系统负载
    ├── mem_combined.sh   # 内存使用 + TOP3 进程
    └── disk.sh           # 磁盘使用率
```

## 模块说明

| 模块 | 说明 | 刷新间隔 |
|------|------|----------|
| cpug | CPU 总使用率 + 历史图表 | 1s |
| cores | 4个 CPU 核心历史图表 | 1s |
| topcpu | CPU 温度 + TOP3 进程 | 2s |
| gpu | GPU 使用率 + 历史图表 | 2s |
| wifi | WiFi 信号强度 + 上下行速度 | 2s |
| load | 系统 1分钟负载 | 5s |
| mem_combined | 内存使用 + TOP3 进程 | 2s |
| disk | 磁盘使用率 | 10s |

## 字体配置

如果遇到 Unicode 方块字符显示错位，请参考 [FONT_ISSUE.md](FONT_ISSUE.md)。

推荐的字体配置：
```css
font-family: "DejaVu Sans Mono", "Liberation Mono", "FreeMono", monospace;
```

## 屏幕适配

默认配置针对 1920px 宽度屏幕优化。如需适配其他分辨率，请修改 `style.css` 中的 `min-width` 值。

## 技术文档

- [spec.md](spec.md) - 详细技术规格
- [testcase.md](testcase.md) - 测试用例
- [FONT_ISSUE.md](FONT_ISSUE.md) - 字体问题总结

## License

MIT
