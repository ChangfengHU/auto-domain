# 快速域名分配 Skill 使用指南

## 概述

`allocate-domain` skill 让用户一句话即可为任何项目分配公网域名，**无需启动项目**。适合：
- 已有本地服务在运行，需要公网访问
- 临时测试某个本地服务的公网访问
- 快速为新项目分配域名而不关心启动方式

## 三种使用方式

### 方式 1：自然语言触发（推荐）

直接对 Copilot 说：

```
给我的 todo 项目分配一个公网域名，它在 localhost:3000 运行

为 myapp 项目申请域名，端口是 5318

allocate a public domain for my project on port 8080

给 chatbot 项目一个公网 URL，端口 4000，用户 alice，域名 example.com
```

**Skill 会自动：**
1. 从你的描述中提取项目名、端口、用户ID、域名
2. 调用 API 注册 tunnel 并分配域名
3. 返回公网地址和 agent 启动命令

### 方式 2：直接运行脚本

在命令行运行（本地或远程服务器）：

```bash
# 基本用法（项目名 + 端口）
./skills/allocate-domain/scripts/allocate-domain.sh myproject 3000

# 指定用户 ID
./skills/allocate-domain/scripts/allocate-domain.sh todo 5318 alice

# 指定用户 ID + 基础域名
./skills/allocate-domain/scripts/allocate-domain.sh app 8080 bob example.com

# 使用自定义 API 地址
./skills/allocate-domain/scripts/allocate-domain.sh myapp 4000 user vyibc.com http://your-api:3002
```

**输出示例：**
```
📋 分配域名信息：
  项目名: myproject
  本地端口: 3000
  用户ID: user
  基础域名: vyibc.com

✅ 域名分配成功！

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
公网地址: http://myproject-a8vau2.vyibc.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📌 完整信息：
  Hostname: myproject-a8vau2.vyibc.com
  Tunnel ID: fa56413f-7261-44f0-b076-dccef24dc7e9
  Token: 4AzizZOBHF00DIb5qho-8ayo6IY8aMCLAYYVI0uCgu4
```

### 方式 3：API 直接调用

```bash
curl -s -X POST 'http://152.32.214.95:3002/control/api/sessions/register' \
  -H 'Content-Type: application/json' \
  -d '{
    "user_id": "alice",
    "project": "myproject",
    "target": "127.0.0.1:3000",
    "base_domain": "vyibc.com"
  }' | jq
```

## 参数说明

| 参数 | 说明 | 默认值 | 例子 |
|------|------|--------|------|
| `PROJECT_NAME` | 项目名称 | 必需 | `myproject`, `todo`, `app` |
| `PORT` | 本地服务端口 | `3000` | `5318`, `8080`, `4000` |
| `USER_ID` | 用户标识 | `user` | `alice`, `bob`, `dev` |
| `BASE_DOMAIN` | 域名后缀 | `vyibc.com` | `example.com`, `test.io` |
| `API_URL` | API 服务地址 | `http://152.32.214.95:3002` | 自定义 API 地址 |

## 返回的信息含义

分配成功后会返回 JSON，包含：

```json
{
  "public_url": "http://myproject-a8vau2.vyibc.com",
  "tunnel": {
    "id": "fa56413f-7261-44f0-b076-dccef24dc7e9",
    "name": "myproject-alice-uh81",
    "token": "4AzizZOBHF00DIb5qho-8ayo6IY8aMCLAYYVI0uCgu4"
  },
  "route": {
    "hostname": "myproject-a8vau2.vyibc.com",
    "target": "127.0.0.1:3000",
    "is_enabled": true
  },
  "agent_command": "./agent -server ws://152.32.214.95/connect -token 4AzizZOBHF00DIb5qho-8ayo6IY8aMCLAYYVI0uCgu4 ..."
}
```

### 字段解释

- **public_url**: 公网访问地址，可直接在浏览器打开（需要本地服务在运行）
- **tunnel_id**: Tunnel 的唯一标识
- **tunnel_token**: 用于 Agent 连接的认证令牌
- **hostname**: 分配的二级域名
- **agent_command**: 启动 Agent 以保持连接的完整命令

## 常见使用场景

### 场景 1：本地开发，临时公网访问

```bash
# 1. 启动本地服务
npm run dev  # 运行在 localhost:3000

# 2. 另开终端，分配域名
./scripts/allocate-domain.sh myproject 3000

# 3. 得到公网地址后，别人可以通过这个地址访问你的本地服务
✅ 公网地址：http://myproject-a8vau2.vyibc.com
```

### 场景 2：为多个项目快速分配域名

```bash
# 项目 1
./scripts/allocate-domain.sh frontend 3000

# 项目 2
./scripts/allocate-domain.sh api 8000

# 项目 3
./scripts/allocate-domain.sh worker 5000
```

### 场景 3：在服务器上为生产服务分配域名

```bash
# 在 152.32.214.95 或其他服务器上
ssh root@your-server
cd /path/to/tunneling
./skills/allocate-domain/scripts/allocate-domain.sh production-app 8080 admin vyibc.com
```

### 场景 4：使用 Copilot 自然语言触发

```
"给我的新项目分配一个公网域名，它在本地 5318 端口运行"

Copilot 会自动：
1. 提取项目名（从当前目录或用户描述）
2. 提取端口：5318
3. 调用 skill
4. 返回公网地址
```

## 后续步骤

获得公网域名后：

1. **访问服务**：在浏览器打开 `public_url`
   - 前提：本地服务必须在指定端口运行

2. **启动 Agent**（可选）：如果想要长期保持连接
   ```bash
   # 使用返回的 agent_command
   ./agent -server ws://152.32.214.95/connect \
     -token 4AzizZOBHF00DIb5qho-8ayo6IY8aMCLAYYVI0uCgu4 \
     ...
   ```

3. **管理域名**：访问 http://152.32.214.95:3002 管理 tunnel 和 route

## 故障排除

### 问题：API 返回错误
**症状**：`curl: (7) Failed to connect to 152.32.214.95 port 3002`
**解决**：检查网络连接，确保能访问 http://152.32.214.95:3002

### 问题：域名分配成功但访问失败
**症状**：`404 Not Found` 或 `Connection refused`
**解决**：
1. 检查本地服务是否在指定端口运行：`lsof -i :3000`
2. 确保防火墙允许访问该端口
3. 启动本地服务：`npm run dev`（如果还没启动）

### 问题：获得的域名已被使用
**症状**：`API 返回 409 Conflict`
**解决**：脚本会自动重试生成新的随机后缀，等待几秒后重新运行

## 参考链接

- Skill 源代码：`skills/allocate-domain/`
- API 文档：`docs/PROJECT_ONBOARDING.md`
- Control API：`http://152.32.214.95:3002/control/api/`
