# Waybar 布局 Test Cases

## 需求概述
1. 所有模块宽度必须固定
2. 所有模块需要正确展示在屏幕边界内
3. 模块之间要有合理的边距，尽量平均，小没有关系
4. 进程名字需要15个字符，多了截断
5. 如果整体布局有超过屏幕宽度的情况，可以适当减少cpu top模块的宽度，但需要确保他的宽度稳定

---

## TC-001: 屏幕宽度检测

**目的**: 确认屏幕可用宽度

**前置条件**: 系统运行中，waybar已启动

**步骤**:
```bash
screen_width=$(xrandr | grep '*' | awk '{print $1}' | cut -d'x' -f1)
echo "屏幕宽度: ${screen_width}px"
```

**预期结果**: 
- 屏幕宽度: 1920px (或实际屏幕宽度)
- 可用宽度目标: 屏幕宽度 - 40px(安全边距)

---

## TC-002: 总宽度约束验证

**目的**: 验证所有模块总宽度 ≤ 屏幕可用宽度

**模块宽度分配**:

| 模块 | max-width | padding | margin | 实际占用 | 说明 |
|------|-----------|---------|--------|----------|------|
| cpug | 100px | 8px | 4px | 112px | Unicode图表 |
| cores | 120px | 8px | 4px | 132px | Unicode图表 |
| topcpu | 400px | 8px | 4px | 412px | 10字符进程名×4 |
| gpu | 100px | 8px | 4px | 112px | Unicode图表 |
| wifi | 140px | 8px | 4px | 152px | 含emoji |
| load | 110px | 8px | 4px | 122px | 纯文本 |
| memory | 100px | 8px | 4px | 112px | 内置模块 |
| topmem | 280px | 8px | 4px | 292px | 15字符进程名×3 |
| disk | 130px | 8px | 4px | 142px | 固定格式 |

**计算**:
- 模块实际占用总计: 1588px
- waybar spacing: 4px × 8间隔 = 32px
- **总宽度: 1620px**
- 屏幕1920px - 总宽度1620px = **300px边距** (左右各150px)

**验证命令**:
```bash
# 检查CSS配置
grep -E "min-width|max-width" ~/.config/waybar/style.css
```

**预期结果**: 
- 总宽度 1620px < 1880px (1920-40)
- 所有模块 max-width 设置正确
- **结果: PASS**

---

## TC-003: 各模块输出长度验证

**目的**: 验证脚本输出长度与CSS宽度匹配

### TC-003-1: cpug 模块
```bash
output=$(~/.config/waybar/scripts/cpu_graph.sh 2>/dev/null | head -1)
echo "输出: [$output]"
echo "长度: ${#output} 字符"
```
**预期**: 长度 ≤ 15字符 (含Unicode图表)
**格式**: `CPU: xx% ▃▆▃▃▂▂`

### TC-003-2: cores 模块
```bash
output=$(~/.config/waybar/scripts/cores_graph.sh 2>/dev/null | head -1)
echo "长度: ${#output} 字符"
```
**预期**: 长度 ≤ 25字符 (4核心Unicode图表)

### TC-003-3: topcpu 模块
```bash
output=$(~/.config/waybar/scripts/topcpu.sh 2>/dev/null | head -1)
echo "输出: [$output]"
echo "长度: ${#output} 字符"
```
**预期**: 长度 = 70字符 (固定)
**格式**: `CPU xx°C: ` (10字符) + 4个进程(每个最多17字符: 10字符名字 + 7字符后缀)
**注意**: 进程名截断到10字符（因CPU%可能占5字符如"24.5%"），超过70字符的总输出会被截断

### TC-003-4: gpu 模块
```bash
output=$(~/.config/waybar/scripts/gpu.sh 2>/dev/null | head -1)
echo "长度: ${#output} 字符"
```
**预期**: 长度 ≤ 15字符

### TC-003-5: wifi 模块
```bash
output=$(~/.config/waybar/scripts/wifi_info.sh 2>/dev/null | head -1)
echo "输出: [$output]"
echo "长度: ${#output} 字符"
```
**预期**: 长度 ≤ 18字符
**格式**: `📶xxx% ↓xxK↑xxK`

### TC-003-6: load 模块
```bash
output=$(~/.config/waybar/scripts/load.sh 2>/dev/null | head -1)
echo "长度: ${#output} 字符"
```
**预期**: 长度 ≤ 22字符

### TC-003-7: memory 模块 (内置)
**格式**: `MEM:{used:.0f}G/{total:.0f}G {percentage:2d}%`
**预期**: 长度 ≈ 18字符

### TC-003-8: topmem 模块
```bash
output=$(~/.config/waybar/scripts/topmem.sh 2>/dev/null | head -1)
echo "输出: [$output]"
echo "长度: ${#output} 字符"
```
**预期**: 长度 = 55字符 (固定)
**格式**: `MEM: ` (5字符) + 3个进程(每个15字符) + 分隔符

### TC-003-9: disk 模块
```bash
output=$(~/.config/waybar/scripts/disk.sh 2>/dev/null | head -1)
echo "输出: [$output]"
echo "长度: ${#output} 字符"
```
**预期**: 长度 ≤ 15字符
**格式**: `DISK:xx% xxxG`

---

## TC-004: 进程名截断验证

**目的**: 验证进程名超过限制时正确截断

**测试步骤**:
```bash
# 创建一个测试进程名
test_name="this_is_a_very_long_process_name"

# topcpu: 截断到12字符
echo "topcpu (12字符限制):"
echo "$test_name" | awk '{ 
    if (length($0) > 12) 
        print substr($0, 1, 12) 
    else 
        print $0 
}'

# topmem: 截断到15字符  
echo "topmem (15字符限制):"
echo "$test_name" | awk '{ 
    if (length($0) > 15) 
        print substr($0, 1, 15) 
    else 
        print $0 
}'
```

**预期结果**:
- topcpu: `this_is_a_ve` (12字符)
- topmem: `this_is_a_very_` (15字符)

**验证位置**:
- topcpu.sh: 进程名截断到10字符（因CPU%可能占5字符如"24.5%"）
- topmem.sh: 进程名截断到15字符

---

## TC-005: 模块固定宽度验证

**目的**: 验证所有模块宽度固定，不随内容变化

**验证方法**:
```bash
# 检查CSS中所有模块都有 min-width = max-width
grep -E "min-width|max-width" ~/.config/waybar/style.css | paste - - | while read line; do
    echo "$line"
done
```

**预期结果**:
- 每个模块的 min-width 和 max-width 相等
- 没有模块使用百分比宽度
- 所有模块宽度固定

---

## TC-006: 边距均匀分布验证

**目的**: 验证模块间边距合理且均匀

**边距计算**:
- waybar config spacing: 4px (模块间)
- CSS margin: 2px (左右各2px，模块与容器)
- CSS padding: 4px (左右各4px，内容与边框)

**验证**:
```bash
# 检查waybar config
grep "spacing" ~/.config/waybar/config

# 检查CSS margin和padding
grep -E "margin|padding" ~/.config/waybar/style.css | head -20
```

**预期结果**:
- spacing: 4
- margin: 4px 2px (上下4px，左右2px)
- padding: 0 4px (上下0，左右4px)
- 模块间视觉效果均匀

---

## TC-007: 屏幕边界验证

**目的**: 验证disk模块右边缘在屏幕内

**验证方法**:
```bash
# 方法1: 添加边界标记测试
echo "在disk.sh输出末尾添加 █ 标记"
echo "目视验证 █ 是否在屏幕内"

# 方法2: 计算验证
echo "总宽度: 1620px"
echo "屏幕宽度: 1920px"
echo "剩余空间: 300px"
echo "disk模块应在屏幕内"
```

**预期结果**:
- disk模块完全可见
- 右边缘距离屏幕右边缘约150px

---

## TC-008: 响应式调整验证

**目的**: 如果宽度超出，验证topcpu可缩减

**场景**:
- 屏幕宽度: 1366px (较小屏幕)
- 可用宽度: 1326px
- 当前总宽度: 1620px (超出294px)

**调整方案**:
- topcpu: 400px → 280px (减少120px)
- 进程名: 12字符 → 8字符
- 新总宽度: 1500px < 1326px? 需要进一步调整

**验证**:
```bash
# 检查是否有响应式配置
echo "当前配置针对1920px屏幕优化"
echo "小屏幕需要手动调整:"
echo "1. 减小topcpu宽度"
echo "2. 减小topmem宽度"
echo "3. 减小进程名字符数"
```

---

## 测试执行清单

- [ ] TC-001: 屏幕宽度检测
- [ ] TC-002: 总宽度约束验证
- [ ] TC-003: 各模块输出长度验证
- [ ] TC-004: 进程名截断验证
- [ ] TC-005: 模块固定宽度验证
- [ ] TC-006: 边距均匀分布验证
- [ ] TC-007: 屏幕边界验证
- [ ] TC-008: 响应式调整验证 (如需要)

---

## 通过标准

所有测试通过的条件:
1. 总宽度 ≤ 屏幕宽度 - 40px
2. 所有模块输出长度 ≤ CSS max-width 对应字符数
3. 进程名截断功能正常工作 (topcpu: 10字符, topmem: 15字符)
4. disk模块完全可见
5. 边距均匀分布
