#!/usr/bin/env bash
# Fully autonomous: detect project → fix env → start tunnel → print public URL
# No user interaction needed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_DIR="${1:-$(pwd)}"
PORT="${2:-}"

cd "${PROJECT_DIR}"

# ── 1. Detect port ───────────────────────────────────────────────────────────
if [[ -z "${PORT}" ]]; then
  # Try package.json scripts for common port patterns
  if command -v python3 >/dev/null 2>&1; then PY=python3; elif command -v python >/dev/null 2>&1; then PY=python; else PY=""; fi
  if [[ -n "$PY" && -f "package.json" ]]; then
    PORT="$($PY -c "
import json,re,sys
d=json.load(open('package.json'))
scripts=' '.join(d.get('scripts',{}).values())
m=re.search(r'(?:PORT=|--port\s+|:\s*)(\d{4,5})',scripts)
print(m.group(1) if m else '')
" 2>/dev/null || true)"
  fi
  # Common defaults by framework
  if [[ -z "${PORT}" ]]; then
    if [[ -f "next.config.js" || -f "next.config.ts" || -f "next.config.mjs" ]]; then PORT=3000
    elif [[ -f "vite.config.js" || -f "vite.config.ts" ]]; then PORT=5173
    elif [[ -f "nuxt.config.js" || -f "nuxt.config.ts" ]]; then PORT=3000
    elif [[ -f "angular.json" ]]; then PORT=4200
    elif [[ -f "svelte.config.js" ]]; then PORT=5173
    else PORT=3000
    fi
  fi
fi

# ── 2. Install latest project-tunnel.sh ─────────────────────────────────────
ASSET="${SKILL_ROOT}/assets/project-tunnel.sh"
TARGET="${PROJECT_DIR}/project-tunnel.sh"
cp "${ASSET}" "${TARGET}"
chmod +x "${TARGET}"

# ── 3. Fix environment if needed ─────────────────────────────────────────────
ENV_OUT="$("${SCRIPT_DIR}/check_env.sh" 2>&1)" || true
if echo "${ENV_OUT}" | grep -q "❌"; then
  MISSING="$(echo "${ENV_OUT}" | sed 's/.*missing: //')"
  echo "[auto] fixing environment: ${MISSING}"
  # shellcheck disable=SC2086
  "${SCRIPT_DIR}/fix_env.sh" ${MISSING}
fi

# ── 4. Start tunnel ───────────────────────────────────────────────────────────
echo "[auto] starting tunnel for ${PROJECT_DIR} on port ${PORT}..."
exec sh "${TARGET}" start --port "${PORT}"
