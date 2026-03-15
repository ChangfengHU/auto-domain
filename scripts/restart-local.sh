#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="${ROOT_DIR}/.local/run"
LOG_DIR="${ROOT_DIR}/.local/logs"
BIN_DIR="${ROOT_DIR}/.local/bin"
ENV_CONTROL_FILE="${ENV_CONTROL_FILE:-${ROOT_DIR}/.env.control}"

CONTROL_ADDR="${CONTROL_ADDR:-:18100}"
SERVER_PUBLIC_ADDR="${SERVER_PUBLIC_ADDR:-:8080}"
SERVER_CONTROL_ADDR="${SERVER_CONTROL_ADDR:-:9000}"
SERVER_CONTROL_API="${SERVER_CONTROL_API:-http://127.0.0.1:18100}"
SERVER_ROUTE_SYNC_PATH="${SERVER_ROUTE_SYNC_PATH:-/_tunnel/agent/routes}"
CONSOLE_PORT="${CONSOLE_PORT:-3002}"
CONSOLE_CONTROL_API_BASE="${CONSOLE_CONTROL_API_BASE:-http://127.0.0.1:18100}"

mkdir -p "${RUN_DIR}" "${LOG_DIR}" "${BIN_DIR}"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/restart-local.sh start [all|control|server|console]
  ./scripts/restart-local.sh stop [all|control|server|console]
  ./scripts/restart-local.sh restart [all|control|server|console]
  ./scripts/restart-local.sh status [all|control|server|console]

Default component: all
EOF
}

resolve_components() {
  local target="${1:-all}"
  case "${target}" in
    all) echo "control server console" ;;
    control|server|console) echo "${target}" ;;
    *)
      echo "Unknown component: ${target}" >&2
      usage
      exit 1
      ;;
  esac
}

pid_file() {
  echo "${RUN_DIR}/$1.pid"
}

log_file() {
  echo "${LOG_DIR}/$1.log"
}

bin_file() {
  echo "${BIN_DIR}/$1"
}

component_port() {
  case "$1" in
    control) echo "${CONTROL_ADDR#:}" ;;
    server) echo "${SERVER_CONTROL_ADDR#:}" ;;
    console) echo "${CONSOLE_PORT}" ;;
  esac
}

is_running() {
  local pid="$1"
  [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null
}

read_pid() {
  local file
  file="$(pid_file "$1")"
  if [[ -f "${file}" ]]; then
    tr -d '[:space:]' <"${file}"
  fi
}

clear_pid() {
  rm -f "$(pid_file "$1")"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

spawn_bg() {
  local pid_dest="$1"
  local logfile="$2"
  shift 2

  if command -v setsid >/dev/null 2>&1; then
    setsid "$@" >"${logfile}" 2>&1 < /dev/null &
  else
    nohup "$@" >"${logfile}" 2>&1 < /dev/null &
  fi
  echo $! >"${pid_dest}"
}

port_pid() {
  local port="$1"
  (lsof -tiTCP:"${port}" -sTCP:LISTEN 2>/dev/null || true) | head -n 1
}

release_port() {
  local name="$1"
  local port="$2"
  local expected_pid="${3:-}"
  local listener_pid
  listener_pid="$(port_pid "${port}")"
  if [[ -z "${listener_pid}" ]]; then
    return 0
  fi
  if [[ -n "${expected_pid}" && "${listener_pid}" == "${expected_pid}" ]]; then
    return 0
  fi
  echo "[info] ${name} port ${port} is in use by pid=${listener_pid}, stopping it"
  kill "${listener_pid}" 2>/dev/null || true
  local i
  for ((i = 1; i <= 10; i += 1)); do
    if [[ -z "$(port_pid "${port}")" ]]; then
      return 0
    fi
    sleep 1
  done
  listener_pid="$(port_pid "${port}")"
  if [[ -n "${listener_pid}" ]]; then
    echo "[info] ${name} port ${port} still busy, force killing pid=${listener_pid}"
    kill -9 "${listener_pid}" 2>/dev/null || true
    sleep 1
  fi
  if [[ -n "$(port_pid "${port}")" ]]; then
    echo "[error] ${name} cannot start: port ${port} is still in use" >&2
    exit 1
  fi
}

source_control_env() {
  if [[ -f "${ENV_CONTROL_FILE}" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${ENV_CONTROL_FILE}"
    set +a
  fi
}

wait_for_http() {
  local name="$1"
  local url="$2"
  local attempts="${3:-30}"
  local i
  for ((i = 1; i <= attempts; i += 1)); do
    if curl -fsS "${url}" >/dev/null 2>&1; then
      echo "[ok] ${name} is ready: ${url}"
      return 0
    fi
    sleep 1
  done
  echo "[warn] ${name} did not become ready in time: ${url}" >&2
  return 1
}

start_component() {
  local name="$1"
  local pid
  pid="$(read_pid "${name}")"
  if is_running "${pid}"; then
    echo "[skip] ${name} already running (pid=${pid})"
    return 0
  fi

  clear_pid "${name}"
  local logfile
  logfile="$(log_file "${name}")"

  case "${name}" in
    control)
      require_cmd go
      source_control_env
      : "${SUPABASE_URL:?SUPABASE_URL is required. Put it in .env.control or export it.}"
      : "${SUPABASE_SERVICE_ROLE_KEY:?SUPABASE_SERVICE_ROLE_KEY is required. Put it in .env.control or export it.}"
      release_port "control" "${CONTROL_ADDR#:}" "${pid}"
      (
        cd "${ROOT_DIR}"
        go build -o "$(bin_file control-local)" ./cmd/control
        spawn_bg "$(pid_file control)" "${logfile}" "$(bin_file control-local)" -addr "${CONTROL_ADDR}"
      )
      wait_for_http "control" "http://127.0.0.1:${CONTROL_ADDR#:}/healthz"
      port_pid "$(component_port control)" >"$(pid_file control)"
      ;;
    server)
      require_cmd go
      release_port "server public" "${SERVER_PUBLIC_ADDR#:}" "${pid}"
      release_port "server control" "${SERVER_CONTROL_ADDR#:}" "${pid}"
      (
        cd "${ROOT_DIR}"
        go build -o "$(bin_file server-local)" ./cmd/server
        spawn_bg "$(pid_file server)" "${logfile}" "$(bin_file server-local)" \
          -public-addr "${SERVER_PUBLIC_ADDR}" \
          -control-addr "${SERVER_CONTROL_ADDR}" \
          -control-api "${SERVER_CONTROL_API}" \
          -route-sync-path "${SERVER_ROUTE_SYNC_PATH}"
      )
      wait_for_http "server-control" "http://127.0.0.1:${SERVER_CONTROL_ADDR#:}/healthz"
      port_pid "$(component_port server)" >"$(pid_file server)"
      ;;
    console)
      require_cmd npm
      if [[ ! -f "${ROOT_DIR}/console/package.json" ]]; then
        echo "console/package.json not found" >&2
        exit 1
      fi
      release_port "console" "${CONSOLE_PORT}" "${pid}"
      (
        cd "${ROOT_DIR}/console"
        spawn_bg "$(pid_file console)" "${logfile}" env PORT="${CONSOLE_PORT}" CONTROL_API_BASE="${CONSOLE_CONTROL_API_BASE}" npm run dev
      )
      wait_for_http "console" "http://127.0.0.1:${CONSOLE_PORT}"
      port_pid "$(component_port console)" >"$(pid_file console)"
      ;;
  esac

  echo "[start] ${name} pid=$(read_pid "${name}") log=${logfile}"
}

stop_component() {
  local name="$1"
  local pid
  pid="$(read_pid "${name}")"
  if ! is_running "${pid}"; then
    clear_pid "${name}"
    echo "[skip] ${name} is not running"
    return 0
  fi

  kill "${pid}" 2>/dev/null || true
  local i
  for ((i = 1; i <= 10; i += 1)); do
    if ! is_running "${pid}"; then
      clear_pid "${name}"
      echo "[stop] ${name} stopped"
      return 0
    fi
    sleep 1
  done

  kill -9 "${pid}" 2>/dev/null || true
  clear_pid "${name}"
  echo "[stop] ${name} killed"
}

status_component() {
  local name="$1"
  local pid logfile live_pid
  pid="$(read_pid "${name}")"
  logfile="$(log_file "${name}")"
  live_pid="$(port_pid "$(component_port "${name}")")"
  if [[ -n "${live_pid}" ]]; then
    echo "${live_pid}" >"$(pid_file "${name}")"
    pid="${live_pid}"
  fi
  if is_running "${pid}"; then
    echo "[up] ${name} pid=${pid} log=${logfile}"
  else
    echo "[down] ${name} log=${logfile}"
  fi
}

ACTION="${1:-restart}"
TARGET="${2:-all}"
COMPONENTS="$(resolve_components "${TARGET}")"

case "${ACTION}" in
  start)
    for component in ${COMPONENTS}; do
      start_component "${component}"
    done
    ;;
  stop)
    for component in ${COMPONENTS}; do
      stop_component "${component}"
    done
    ;;
  restart)
    for component in ${COMPONENTS}; do
      stop_component "${component}"
    done
    for component in ${COMPONENTS}; do
      start_component "${component}"
    done
    ;;
  status)
    for component in ${COMPONENTS}; do
      status_component "${component}"
    done
    ;;
  *)
    usage
    exit 1
    ;;
esac
