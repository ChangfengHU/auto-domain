---
name: project-tunnel-bootstrap
description: >
  当用户说"启动项目"、"给项目一个公网域名"、"start tunnel"、"expose my project"、
  "让项目可以公网访问"、"start my project with a public URL" 时自动触发。
  无需用户做任何操作：自动检测项目目录和端口，修复环境，启动 tunnel，
  直接返回公网域名 URL。
---

# Project Tunnel Bootstrap

**一句话触发，全自动执行，直接给出公网 URL。用户什么都不需要做。**

---

## Agent 执行步骤（全自动，无需用户介入）

```
用户说：启动我的项目，给我一个公网域名
         ↓
1. 确认当前项目目录（pwd 或用户提到的目录）
2. 运行 scripts/auto_start.sh [project_dir] [port]
         ↓
   auto_start.sh 自动完成：
   ├─ 检测端口（从 package.json / 框架类型自动判断）
   ├─ 安装/更新 project-tunnel.sh 到项目目录
   ├─ 检测环境（python3/python, curl, node, npm, lsof）
   ├─ 自动安装缺失工具（brew / apt / yum）
   └─ 启动 tunnel
         ↓
3. 从输出中提取 public_url
4. 直接告诉用户：
   "✅ 你的项目已公网可访问：https://xxx-huchangfeng.vyibc.com"
```

---

## 调用方式

**标准调用（AI agent 使用）：**
```bash
# 当前目录，自动检测端口
scripts/auto_start.sh

# 指定目录和端口
scripts/auto_start.sh /Users/huchangfeng/todo-katong 4545
```

**输出格式（从中提取 public_url）：**
```
[DONE]
project: todo-katong
hostname: todo-katong-huchangfeng.vyibc.com
public_url: https://todo-katong-huchangfeng.vyibc.com   ← 返回给用户这行
tunnel_id: 5b29718c-...
target: http://127.0.0.1:4545
public_probe code=200 ...
```

---

## 触发关键词示例

- "启动我的项目"
- "给我的项目一个公网域名"
- "让外网能访问我的项目"
- "start tunnel for my project"
- "expose port 3000 to the internet"
- "给我一个公网 URL"
- "start my project with a public URL"
- **"用 npm run dev 启动我的项目"** → 自动加 `--start-cmd "npm run dev"`
- **"用 scripts/start.sh 启动"** → 自动加 `--startsh scripts/start.sh`
- **"用端口 4545 启动"** → 自动传 port=4545

---

## 端口自动检测规则

| 框架 | 默认端口 |
|------|---------|
| Next.js | 3000 |
| Vite / Svelte | 5173 |
| Nuxt | 3000 |
| Angular | 4200 |
| 其他 / 未识别 | 3000 |
| package.json scripts 中有 `PORT=XXXX` | 自动读取 |

---

## 环境问题处理

如果 `auto_start.sh` 报错：
```bash
scripts/check_env.sh          # 查看缺少哪些工具
scripts/fix_env.sh python3    # 修复指定工具
scripts/auto_start.sh         # 重试
```
