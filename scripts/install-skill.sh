#!/usr/bin/env bash
# install-skill.sh - 一键安装 allocate-domain skill
#
# 用法:
#   bash <(curl -fsSL https://raw.githubusercontent.com/ChangfengHU/auto-domain/main/scripts/install-skill.sh)
#
# 可选参数:
#   --skill <name>   指定要安装的 skill（默认: allocate-domain）
#   --dir   <path>   指定安装目录（默认: ~/.codex/skills）

set -euo pipefail

# ── 参数解析 ──────────────────────────────────────────────
SKILL_NAME="allocate-domain"
INSTALL_DIR="${HOME}/.codex/skills"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skill) SKILL_NAME="$2"; shift 2 ;;
    --dir)   INSTALL_DIR="$2"; shift 2 ;;
    *) echo "未知参数: $1"; exit 1 ;;
  esac
done

# ── 常量 ─────────────────────────────────────────────────
RAW_BASE="https://raw.githubusercontent.com/ChangfengHU/auto-domain/main"
SKILL_DIR="${INSTALL_DIR}/${SKILL_NAME}"

# ── 工具检测 ──────────────────────────────────────────────
if ! command -v curl &>/dev/null; then
  echo "❌ 需要 curl，请先安装"
  exit 1
fi

echo ""
echo "🚀 安装 skill: ${SKILL_NAME}"
echo "   目标目录: ${SKILL_DIR}"
echo ""

# ── 创建目录结构 ──────────────────────────────────────────
mkdir -p "${SKILL_DIR}/agents"
mkdir -p "${SKILL_DIR}/scripts"

# ── 下载 skill 文件 ───────────────────────────────────────
download() {
  local src="$1"
  local dst="$2"
  echo "  ↓ ${src##*/skills/}"
  curl -fsSL "${RAW_BASE}/skills/${src}" -o "${SKILL_DIR}/${dst}"
}

download "${SKILL_NAME}/SKILL.md"               "SKILL.md"
download "${SKILL_NAME}/agents/openai.yaml"     "agents/openai.yaml"
download "${SKILL_NAME}/scripts/${SKILL_NAME}.sh" "scripts/${SKILL_NAME}.sh"
chmod +x "${SKILL_DIR}/scripts/${SKILL_NAME}.sh"

# ── 完成 ─────────────────────────────────────────────────
echo ""
echo "✅ 安装完成！"
echo ""
echo "   skill 位置: ${SKILL_DIR}"
echo ""
echo "现在你可以对 Copilot 说："
echo "   给我的 myapp 项目分配一个公网域名，它在 localhost:3000 运行"
echo ""
