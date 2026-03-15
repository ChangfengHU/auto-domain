#!/usr/bin/env bash
# allocate-domain.sh - 快速为项目分配公网域名
# 用法: ./allocate-domain.sh <project_name> <port> [user_id] [base_domain] [api_url]

set -euo pipefail

# 默认值
API_URL="${5:-https://domain.vyibc.com}"
PROJECT_NAME="${1:-}"
PORT="${2:-3000}"
USER_ID="${3:-user}"
BASE_DOMAIN="${4:-vyibc.com}"
SUBDOMAIN="${SUBDOMAIN:-}"
ADMIN_KEY="${ADMIN_KEY:-}"
MACHINE_DIR="${HOME}/.tunneling"
MACHINE_STATE_FILE="${MACHINE_DIR}/machine_state.json"

# 验证参数
if [[ -z "$PROJECT_NAME" ]]; then
    echo "❌ 错误：项目名称是必须的"
    echo ""
    echo "用法："
    echo "  $0 <project_name> [port] [user_id] [base_domain] [api_url]"
    echo ""
    echo "示例："
    echo "  $0 myproject 3000"
    echo "  $0 todo 5318 alice vyibc.com"
    echo "  $0 app 8080 - - https://domain.vyibc.com"
    exit 1
fi

# 验证端口是否为数字
if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
    echo "❌ 错误：端口必须是数字，得到: $PORT"
    exit 1
fi

echo "📋 分配域名信息："
echo "  项目名: $PROJECT_NAME"
echo "  本地端口: $PORT"
echo "  用户ID: $USER_ID"
echo "  基础域名: $BASE_DOMAIN"
echo "  指定二级域名: ${SUBDOMAIN:-<默认使用项目名>}"
echo "  API 地址: $API_URL"
echo ""

EXISTING_TUNNEL_ID=""
EXISTING_TUNNEL_TOKEN=""
if [[ -f "$MACHINE_STATE_FILE" ]]; then
    EXISTING_TUNNEL_ID=$(python3 - "$MACHINE_STATE_FILE" <<'PY'
import json
import sys
try:
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        data = json.load(f)
    print(data.get("tunnel_id", ""))
except Exception:
    print("")
PY
)
    EXISTING_TUNNEL_TOKEN=$(python3 - "$MACHINE_STATE_FILE" <<'PY'
import json
import sys
try:
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        data = json.load(f)
    print(data.get("tunnel_token", ""))
except Exception:
    print("")
PY
)
fi

# 调用 API
echo "🔗 正在调用 API..."
PAYLOAD=$(python3 - "$USER_ID" "$PROJECT_NAME" "$PORT" "$BASE_DOMAIN" "$EXISTING_TUNNEL_ID" "$EXISTING_TUNNEL_TOKEN" "$SUBDOMAIN" <<'PY'
import json
import sys

user_id, project, port, base_domain, tunnel_id, tunnel_token, subdomain = sys.argv[1:8]
payload = {
    "user_id": user_id,
    "project": project,
    "target": f"127.0.0.1:{port}",
    "base_domain": base_domain,
}
if subdomain:
    payload["subdomain"] = subdomain
if tunnel_id and tunnel_token:
    payload["tunnel_id"] = tunnel_id
    payload["tunnel_token"] = tunnel_token
print(json.dumps(payload, ensure_ascii=False))
PY
)
if [[ -n "$ADMIN_KEY" ]]; then
    RESPONSE=$(curl -s -X POST "$API_URL/api/sessions/register" \
        -H 'Content-Type: application/json' \
        -H "Authorization: Bearer $ADMIN_KEY" \
        -d "$PAYLOAD")
else
    RESPONSE=$(curl -s -X POST "$API_URL/api/sessions/register" \
        -H 'Content-Type: application/json' \
        -d "$PAYLOAD")
fi

# 检查响应是否包含错误
if echo "$RESPONSE" | grep -q '"error"'; then
    echo "❌ API 返回错误："
    echo "$RESPONSE" | grep -o '"error":"[^"]*"'
    exit 1
fi

# 解析响应
PUBLIC_URL=$(echo "$RESPONSE" | grep -o '"public_url":"[^"]*"' | cut -d'"' -f4)
TUNNEL_ID=$(echo "$RESPONSE" | grep -o '"tunnel_id":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "$RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
TUNNEL_TOKEN=$(echo "$RESPONSE" | grep -o '"token":"[^"]*"' | head -1 | cut -d'"' -f4)
HOSTNAME=$(echo "$RESPONSE" | grep -o '"hostname":"[^"]*"' | cut -d'"' -f4)
AGENT_COMMAND=$(echo "$RESPONSE" | grep -o '"agent_command":"[^"]*"' | head -1 | cut -d'"' -f4)

mkdir -p "$MACHINE_DIR"
python3 - "$MACHINE_STATE_FILE" "$USER_ID" "$TUNNEL_ID" "$TUNNEL_TOKEN" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone

path, user_id, tunnel_id, tunnel_token = sys.argv[1:5]
payload = {
    "user_id": user_id,
    "tunnel_id": tunnel_id,
    "tunnel_token": tunnel_token,
    "agent_config": os.path.expanduser("~/.tunneling/machine-agent/config.json"),
    "updated_at": datetime.now(timezone.utc).isoformat(),
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(payload, f, ensure_ascii=False, indent=2)
PY

# 输出结果
echo ""
echo "✅ 域名分配成功！"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 公网地址: $PUBLIC_URL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📌 完整信息："
echo "  Hostname: $HOSTNAME"
echo "  Tunnel ID: $TUNNEL_ID"
echo "  Token: $TUNNEL_TOKEN"
echo "  凭证文件: $MACHINE_STATE_FILE"
echo ""
echo "🚀 后续步骤："
echo "  1. 确保你的项目在 127.0.0.1:$PORT 上运行"
if [[ -n "$AGENT_COMMAND" ]]; then
    echo "  2. 启动本地 Agent："
    echo "     $AGENT_COMMAND"
else
    echo "  2. 启动本地 Agent（使用 control 返回的 agent_command）"
fi
echo "  3. 访问 $PUBLIC_URL 即可从公网访问"
echo ""
echo "提示：若未启动 Agent，公网访问通常会出现 502/404。"
echo ""
echo "📊 管理你的域名："
echo "  访问: https://domain.vyibc.com/login"
echo "  输入 Tunnel ID: $TUNNEL_ID"
echo "  登录后可以修改、启用/禁用你分配的域名"
echo ""

# 完整 JSON 响应（用于脚本处理）
echo "📋 完整 JSON 响应："
echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
