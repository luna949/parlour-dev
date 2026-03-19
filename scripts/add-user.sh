#!/usr/bin/env bash
# ============================================================
# add-user.sh — Provision a new user for a character
#
# Usage:
#   bash add-user.sh \
#     --character "roberto" \
#     --telegram-id "1234567890" \
#     --username "alice"
#
# What this does:
#   1. Creates workspace from character template
#   2. Locks personality files (444)
#   3. Creates data/ directory
#   4. Adds agent entry to gateway config
#   5. Adds Telegram binding
#   6. Restarts gateway to pick up new agent
# ============================================================
set -euo pipefail

CHARACTER=""
TELEGRAM_ID=""
USERNAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --character)   CHARACTER="$2";   shift 2 ;;
    --telegram-id) TELEGRAM_ID="$2"; shift 2 ;;
    --username)    USERNAME="$2";    shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

[[ -z "$CHARACTER" ]]   && echo "Error: --character required"   && exit 1
[[ -z "$TELEGRAM_ID" ]] && echo "Error: --telegram-id required" && exit 1
[[ -z "$USERNAME" ]]    && USERNAME="user-$TELEGRAM_ID"

GATEWAY_DIR="$HOME/.openclaw-$CHARACTER"
CHARACTER_TEMPLATE="$HOME/.openclaw/workspace/projects/companion/characters/$CHARACTER"
AGENT_ID="companion-$(echo "$USERNAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')-$(echo "$TELEGRAM_ID" | tail -c 5)"
WORKSPACE="$GATEWAY_DIR/workspace-$AGENT_ID"
PERSONALITY_FILES=(SOUL.md AGENTS.md ONBOARDING.md MEMORY_SYSTEM.md HEARTBEAT.md APPEARANCE.md BACKSTORY.md USER.md TOOLS.md IDENTITY.md)
IMAGE_GEN_SRC="$HOME/.openclaw-roberto/workspace/skills/image-gen/generate.sh"

echo ""
echo "=== Provisioning user: $USERNAME ($TELEGRAM_ID) → $CHARACTER ==="
echo "    Agent ID:  $AGENT_ID"
echo "    Workspace: $WORKSPACE"
echo ""

[[ ! -d "$GATEWAY_DIR" ]] && echo "Error: character gateway not found: $GATEWAY_DIR" && exit 1
[[ ! -d "$CHARACTER_TEMPLATE" ]] && echo "Error: character template not found: $CHARACTER_TEMPLATE" && exit 1

# ── Create workspace ─────────────────────────────────────────────────────────
echo "[1/4] Creating workspace..."
mkdir -p "$WORKSPACE/data/memory/daily-summaries"

# Copy personality files from master character template
for f in "${PERSONALITY_FILES[@]}"; do
  if [[ -f "$CHARACTER_TEMPLATE/$f" ]]; then
    cp "$CHARACTER_TEMPLATE/$f" "$WORKSPACE/$f"
  fi
done

# Copy skills
mkdir -p "$WORKSPACE/skills/image-gen"
[[ -f "$IMAGE_GEN_SRC" ]] && cp "$IMAGE_GEN_SRC" "$WORKSPACE/skills/image-gen/generate.sh"

# ── Lock personality files ───────────────────────────────────────────────────
echo "[2/4] Locking personality files..."
for f in "${PERSONALITY_FILES[@]}"; do
  [[ -f "$WORKSPACE/$f" ]] && chmod 444 "$WORKSPACE/$f"
done
chmod 755 "$WORKSPACE/data"

# ── Update gateway config ────────────────────────────────────────────────────
echo "[3/4] Updating gateway config..."

CONFIG="$GATEWAY_DIR/openclaw.json"
CHAR_NAME=$(echo "$CHARACTER" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')

# Add agent to list using python3
python3 << PYEOF
import json

with open('$CONFIG') as f:
    config = json.load(f)

# Add agent entry
agent = {
    "id": "$AGENT_ID",
    "name": "$AGENT_ID",
    "workspace": "$WORKSPACE",
    "identity": {"name": "$CHAR_NAME", "emoji": "💬"},
    "sandbox": {
        "mode": "all",
        "scope": "agent",
        "docker": {"image": "parlour-companion:latest"},
        "workspaceAccess": "rw"
    }
}

# Remove existing agent with same id if present
config['agents']['list'] = [a for a in config['agents']['list'] if a['id'] != '$AGENT_ID']
config['agents']['list'].append(agent)

# Add binding
binding = {
    "agentId": "$AGENT_ID",
    "match": {
        "channel": "telegram",
        "peer": {"kind": "direct", "id": "$TELEGRAM_ID"}
    }
}
config['bindings'] = [b for b in config['bindings'] if b['match']['peer']['id'] != '$TELEGRAM_ID']
config['bindings'].append(binding)

with open('$CONFIG', 'w') as f:
    json.dump(config, f, indent=2)

print("  Config updated")
PYEOF

# ── Restart gateway ──────────────────────────────────────────────────────────
echo "[4/4] Restarting gateway..."
systemctl --user restart "${CHARACTER}-gateway"
sleep 3

if systemctl --user is-active --quiet "${CHARACTER}-gateway"; then
  echo "  ✓ Gateway restarted"
else
  echo "  ✗ Gateway failed — check: journalctl --user -u ${CHARACTER}-gateway -n 20"
  exit 1
fi

echo ""
echo "✓ User provisioned!"
echo "  $USERNAME can now message the $CHAR_NAME bot on Telegram"
echo "  Workspace: $WORKSPACE"
echo ""
