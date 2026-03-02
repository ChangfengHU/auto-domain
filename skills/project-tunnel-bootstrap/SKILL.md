---
name: project-tunnel-bootstrap
description: >
  Run project-tunnel.sh in the current project. Automatically installs the script,
  checks the environment, fixes missing tools (python3/python, curl, node, npm, lsof),
  and starts/stops/checks tunnel status. Use when the user wants to start tunneling,
  check tunnel status, or when the environment is missing required tools.
---

# Project Tunnel Bootstrap

**核心职责**：执行 `project-tunnel.sh`。脚本会被自动安装到项目目录。  
如果环境缺少依赖，AI 负责诊断并修复，直到脚本能正常运行。

---

## 主入口（推荐）

```bash
# 启动 tunnel（自动检测环境、安装缺失依赖、运行脚本）
scripts/run_tunnel.sh start --port 3000

# 停止
scripts/run_tunnel.sh stop --port 3000

# 查看状态
scripts/run_tunnel.sh status --port 3000
```

`run_tunnel.sh` 会自动完成：
1. 将最新 `project-tunnel.sh` 复制到当前项目目录
2. 检测环境（python3/python、curl、node、npm、lsof）
3. 发现缺失工具 → 自动安装（macOS 用 brew，Linux 用 apt/yum）
4. 环境 OK 后执行 `project-tunnel.sh`

---

## 单步工具（AI 诊断用）

```bash
# 仅检测环境，不运行脚本
scripts/check_env.sh
# 输出示例：
#   ✅ environment OK
#   ❌ missing: python3 node

# 修复指定工具（AI 诊断后调用）
scripts/fix_env.sh python3 node

# 仅安装脚本到当前项目，不运行
scripts/install_project_tunnel.sh [project_dir]
```

---

## AI 诊断流程

当 `run_tunnel.sh` 报错时，AI 按以下顺序排查：

1. **运行** `scripts/check_env.sh` → 确认缺少哪些工具
2. **运行** `scripts/fix_env.sh <缺失工具>` → 自动安装
3. **再次运行** `scripts/check_env.sh` → 验证修复结果
4. **重新执行** `scripts/run_tunnel.sh start --port <PORT>`

如果自动安装失败（无 sudo 权限、特殊环境等），AI 给出对应平台的手动安装命令。

---

## 环境要求

| 工具 | macOS 安装 | Linux 安装 |
|------|-----------|-----------|
| `curl` | 自带 / `brew install curl` | `apt install curl` |
| `python3` 或 `python`（≥3） | `brew install python3` | `apt install python3` |
| `node` + `npm` | `brew install node` | `apt install nodejs npm` |
| `lsof` | 自带 | `apt install lsof` |

> `go` **不需要**安装，agent 二进制由脚本自动下载到 `~/.tunneling/bin/`

---

## Notes

- `assets/project-tunnel.sh` 是脚本本体，随 skill 版本更新
- 机器级共享 tunnel：同一台机器上所有项目共享一个 tunnel_id，存于 `~/.tunneling/machine_state.json`
- 旧版 `install_project_tunnel.sh` / `start_project_tunnel.sh` 仍保留，向后兼容
