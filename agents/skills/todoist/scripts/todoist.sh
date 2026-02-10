#!/usr/bin/env bash
# Todoist CLI via REST API v2
# Usage: todoist.sh <command> [args...]
# Token read from OpenClaw config or TODOIST_API_TOKEN env var.

set -eo pipefail

API="https://api.todoist.com/rest/v2"
CONFIG="$HOME/.openclaw/openclaw.json"

cmd="${1:-help}"

# Resolve token: env > config
get_token() {
  if [[ -n "${TODOIST_API_TOKEN:-}" ]]; then
    echo "$TODOIST_API_TOKEN"
    return
  fi
  if [[ -f "$CONFIG" ]]; then
    local t
    t=$(jq -r '.skills.entries["todoist"].apiToken // empty' "$CONFIG" 2>/dev/null)
    if [[ -n "$t" ]]; then
      echo "$t"
      return
    fi
  fi
  echo "Error: No token found. Set TODOIST_API_TOKEN or add skills.entries.todoist.apiToken to openclaw.json" >&2
  exit 1
}

if [[ "$cmd" != "help" ]]; then
  token=$(get_token)
fi

auth() { echo "Authorization: Bearer $token"; }
reqid() { uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid; }

case "$cmd" in
  tasks)
    filter="${2:-}"
    if [[ -n "$filter" ]]; then
      curl -sS -X GET "$API/tasks?filter=$(printf '%s' "$filter" | jq -sRr @uri)" -H "$(auth)"
    else
      curl -sS -X GET "$API/tasks" -H "$(auth)"
    fi
    ;;

  task)
    task_id="${2:?task_id required}"
    curl -sS -X GET "$API/tasks/$task_id" -H "$(auth)"
    ;;

  add)
    content="${2:?content required}"
    due_string="${3:-}"
    project_id="${4:-}"

    json="{\"content\":$(echo "$content" | jq -R .)}"
    [[ -n "$due_string" ]] && json=$(echo "$json" | jq --arg d "$due_string" '. + {due_string: $d}')
    [[ -n "$project_id" ]] && json=$(echo "$json" | jq --arg p "$project_id" '. + {project_id: $p}')

    curl -sS -X POST "$API/tasks" \
      -H "$(auth)" \
      -H "Content-Type: application/json" \
      -H "X-Request-Id: $(reqid)" \
      -d "$json"
    ;;

  complete)
    task_id="${2:?task_id required}"
    curl -sS -X POST "$API/tasks/$task_id/close" -H "$(auth)"
    echo '{"ok":true}'
    ;;

  reopen)
    task_id="${2:?task_id required}"
    curl -sS -X POST "$API/tasks/$task_id/reopen" -H "$(auth)"
    echo '{"ok":true}'
    ;;

  update)
    task_id="${2:?task_id required}"
    shift 2
    json="{}"
    for pair in "$@"; do
      key="${pair%%=*}"
      val="${pair#*=}"
      json=$(echo "$json" | jq --arg k "$key" --arg v "$val" '. + {($k): $v}')
    done
    curl -sS -X POST "$API/tasks/$task_id" \
      -H "$(auth)" \
      -H "Content-Type: application/json" \
      -H "X-Request-Id: $(reqid)" \
      -d "$json"
    ;;

  delete)
    task_id="${2:?task_id required}"
    curl -sS -X DELETE "$API/tasks/$task_id" -H "$(auth)"
    echo '{"ok":true}'
    ;;

  projects)
    curl -sS -X GET "$API/projects" -H "$(auth)"
    ;;

  project)
    project_id="${2:?project_id required}"
    curl -sS -X GET "$API/projects/$project_id" -H "$(auth)"
    ;;

  add-project)
    name="${2:?name required}"
    curl -sS -X POST "$API/projects" \
      -H "$(auth)" \
      -H "Content-Type: application/json" \
      -H "X-Request-Id: $(reqid)" \
      -d "{\"name\":$(echo "$name" | jq -R .)}"
    ;;

  labels)
    curl -sS -X GET "$API/labels" -H "$(auth)"
    ;;

  help|*)
    cat <<EOF
Todoist CLI — REST API v2

Commands:
  tasks [filter]                List tasks (optional Todoist filter)
  task <id>                     Get single task
  add <content> [due] [proj]    Create task
  complete <id>                 Complete task
  reopen <id>                   Reopen task
  update <id> key=val...        Update task fields
  delete <id>                   Delete task
  projects                      List projects
  project <id>                  Get single project
  add-project <name>            Create project
  labels                        List labels

Token: reads from openclaw.json (skills.entries.todoist.apiToken) or TODOIST_API_TOKEN env.
EOF
    ;;
esac
