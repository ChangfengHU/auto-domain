---
name: allocate-domain
description: >
  当用户说"给项目分配域名"、"为项目申请公网域名"、"allocate domain"、
  "assign public domain"、"给我的项目一个域名" 时自动触发。
  一句话即可为任何项目分配公网域名，但注册后需启动本地 Agent 才能生效。
---

# 快速域名分配（Allocate Domain）

**一句话注册公网域名。Skill 只关心两件事：本地端口是多少、想用哪个二级域名。注册后需启动本地 Agent 才能生效。**

## 使用场景

- 已有本地服务在某个端口运行，想要分配公网域名
- 想指定固定二级域名，例如 `admin.vyibc.com`
- 同一台机器复用一个 tunnel / 一个 agent，为多个服务增加 route
- 临时公网访问某个本地服务

## 用法示例

```bash
# 最简单：给定端口 + 希望的二级域名
给我的 3000 端口分配公网域名，二级域名用 myapp

# 或从项目配置里推断端口 / 二级域名
给当前项目分配公网域名

# 管理员覆盖注册
以管理员方式把 3001 端口注册成 admin.vyibc.com

# 英文方式
Allocate a domain for localhost:5318 using subdomain myproject
```

## 返回信息

```
✅ 域名分配成功！

🌐 公网地址：http://myproject.vyibc.com

📌 Tunnel 信息：
- Tunnel ID: 68bb4bf9-9a6f-4e21-8aa5-3cfb7dc1cfcb
- Token: dHGAFkpuQx610ShnxCqwbBoJFGHj5y70EDv7RsN26Ds
- Agent Command: ./agent -server ws://... -token ... -route-sync-url ... -tunnel-id ... -tunnel-token ... -admin-addr 127.0.0.1:17001 -config ~/.tunneling/machine-agent/config.json
- 凭证文件: ~/.tunneling/machine_state.json

🚀 后续步骤：
1. 确保项目运行在 127.0.0.1:3000
2. 启动本地 Agent（使用返回的 Agent Command）
3. 访问 http://myproject.vyibc.com 即可公网访问

提示：若未启动 Agent，公网访问通常会出现 502/404。

📊 管理你的域名：
访问 https://domain.vyibc.com/login
输入 Tunnel ID: 68bb4bf9-9a6f-4e21-8aa5-3cfb7dc1cfcb
登录后可以修改、启用/禁用分配的域名
```

## 触发关键词

- "给项目分配域名"
- "为项目申请公网域名"
- "我想要一个公网域名"
- "分配公网地址"
- "allocate domain"
- "assign public domain"
- "get a public URL for my project"

## 环境要求

- `curl` - 用于调用 API
- 网络连接到 https://domain.vyibc.com

## 工作流程

```
用户说：给 3000 端口分配域名，二级域名用 myproject
         ↓
1. 优先从用户输入提取端口和二级域名；没说时再从项目基础配置推断
2. 默认按普通用户注册；只有用户明确要求管理员覆盖时才使用管理员密钥
3. 调用 /api/sessions/register API
4. 解析返回的 tunnel、route 和 agent_command
5. 把 tunnel 凭证统一保存在 ~/.tunneling/machine_state.json
6. 返回 public_url、Tunnel 信息、Agent Command 与管理链接
```
