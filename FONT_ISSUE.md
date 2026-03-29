# Waybar 字体问题总结

## 问题现象
waybar 中 Unicode 方块字符 (`▃▆▇█`) 和英文字符宽度不一致，导致布局错位。

## 根本原因

### 1. 字体回退机制
当主字体没有某个字符时，系统会回退到其他字体显示该字符。

### 2. 问题配置（修复前）
```css
font-family: "JetBrains Mono", "Fira Code", "Noto Sans Mono CJK SC", monospace;
```

**实际使用情况**:
| 字符类型 | 使用的字体 | 是否等宽 |
|---------|-----------|---------|
| 英文字母/数字 | Liberation Mono | ✅ 等宽 |
| Unicode 方块字符 (▃▆▇█) | Noto Sans CJK SC | ❌ **比例字体** |

**问题**: 方块字符回退到 Noto Sans CJK SC（比例字体），与英文字符宽度不一致。

## 解决方案

### 最终配置
```css
font-family: "DejaVu Sans Mono", "Liberation Mono", "FreeMono", "Noto Sans Mono CJK SC", monospace;
```

### 字体选择标准

| 字体 | 方块字符支持 | 等宽 | 优先级 |
|------|-------------|------|--------|
| DejaVu Sans Mono | ✅ | ✅ | 1 (首选) |
| Liberation Mono | ✅ | ✅ | 2 (备用) |
| FreeMono | ✅ | ✅ | 3 (备用) |
| Noto Sans Mono CJK SC | ✅ | ❌ | 4 (仅用于中日韩文字) |

### 验证命令
```bash
# 检查方块字符使用哪个字体
fc-match "DejaVu Sans Mono:charset=2581"  # U+2581 ▁
fc-match "DejaVu Sans Mono:charset=2588"  # U+2588 █

# 检查字体是否等宽
fc-query /usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf | grep spacing
# 输出: spacing: 100(i)(s)  表示等宽
```

## 关键结论

1. **Unicode 字符是走字体的** - 不是系统直接渲染
2. **字体回退可能导致宽度不一致** - 不同字体的字符宽度可能不同
3. **必须选择支持目标 Unicode 字符的等宽字体** - 确保所有字符等宽
4. **DejaVu Sans Mono 是最佳选择** - 支持完整的 Unicode 方块字符且等宽

## 预防措施

1. 使用 `fc-match` 验证字符实际使用的字体
2. 优先使用 DejaVu Sans Mono 或 Liberation Mono
3. 避免混用比例字体和等宽字体显示同一行内容
4. 如需使用 emoji，考虑用 ASCII 字符替代（如用 `W` 代替 `📶`）
