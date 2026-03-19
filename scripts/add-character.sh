#!/usr/bin/env bash
# ============================================================
# add-character.sh — Add a new Parlour character in one command
#
# Usage:
#   source ~/projects/companion/load-secrets.sh  # optional, if token in pass
#   bash add-character.sh \
#     --name "Ava" \
#     --id "ava" \
#     --bot-token "1234567890:AABBcc..." \
#     --port 18796 \
#     --personality /path/to/ava/personality/
#
# What this does:
#   1. Creates gateway directory ~/.openclaw-<id>/
#   2. Copies personality files from --personality dir
#   3. Locks personality files (444)
#   4. Creates pre-seeded data/ directories
#   5. Copies image-gen skill
#   6. Writes openclaw.json config
#   7. Copies auth credentials from Luna
#   8. Creates systemd user service
#   9. Starts the gateway
#  10. Registers Telegram webhook
#
# Prerequisites:
#   - OpenClaw installed
#   - Luna's gateway running
#   - Valid Telegram bot token
# ============================================================
set -euo pipefail

# ── Parse arguments ───────────────────────────────────────────────────────────
NAME=""
ID=""
BOT_TOKEN=""
PORT=""
PERSONALITY_DIR=""
MODEL="google/gemini-3-pro-preview"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)        NAME="$2";          shift 2 ;;
    --id)          ID="$2";            shift 2 ;;
    --bot-token)   BOT_TOKEN="$2";     shift 2 ;;
    --port)        PORT="$2";          shift 2 ;;
    --personality) PERSONALITY_DIR="$2"; shift 2 ;;
    --model)       MODEL="$2";         shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# ── Validate ──────────────────────────────────────────────────────────────────
[[ -z "$NAME" ]]             && echo "Error: --name required"        && exit 1
[[ -z "$ID" ]]               && echo "Error: --id required"          && exit 1
[[ -z "$BOT_TOKEN" ]]        && echo "Error: --bot-token required"   && exit 1
[[ -z "$PORT" ]]             && echo "Error: --port required"        && exit 1
[[ -z "$PERSONALITY_DIR" ]]  && echo "Error: --personality required" && exit 1
[[ ! -d "$PERSONALITY_DIR" ]] && echo "Error: personality dir not found: $PERSONALITY_DIR" && exit 1

GATEWAY_DIR="$HOME/.openclaw-$ID"
OPENCLAW_BIN="$HOME/.npm-global/bin/openclaw"
LUNA_AUTH="$HOME/.openclaw/agents/main/agent/auth-profiles.json"
IMAGE_GEN_SRC="$HOME/.openclaw-roberto/workspace/skills/image-gen/generate.sh"
SERVICE_NAME="${ID}-gateway"

echo ""
echo "=== Adding character: $NAME (id: $ID) ==="
echo "    Port:    $PORT"
echo "    Model:   $MODEL"
echo "    Gateway: $GATEWAY_DIR"
echo ""

# ── Step 1: Directory structure ───────────────────────────────────────────────
echo "[1/9] Creating directory structure..."

[[ -d "$GATEWAY_DIR" ]] && echo "  WARNING: $GATEWAY_DIR already exists, continuing..." || true
mkdir -p "$GATEWAY_DIR"/{workspace,agents/main/agent}

# ── Step 2: Copy personality files ───────────────────────────────────────────
echo "[2/9] Copying personality files..."

PERSONALITY_FILES=(SOUL.md AGENTS.md ONBOARDING.md MEMORY_SYSTEM.md HEARTBEAT.md APPEARANCE.md BACKSTORY.md USER.md TOOLS.md IDENTITY.md)

for f in "${PERSONALITY_FILES[@]}"; do
  if [[ -f "$PERSONALITY_DIR/$f" ]]; then
    cp "$PERSONALITY_DIR/$f" "$GATEWAY_DIR/workspace/$f"
    echo "  Copied: $f"
  fi
done

# ── Step 3: Lock personality files ───────────────────────────────────────────
echo "[3/9] Locking personality files (444)..."
for f in "${PERSONALITY_FILES[@]}"; do
  [[ -f "$GATEWAY_DIR/workspace/$f" ]] && chmod 444 "$GATEWAY_DIR/workspace/$f"
done

# ── Step 4: Create data directories ──────────────────────────────────────────
echo "[4/9] Creating data directories..."
mkdir -p "$GATEWAY_DIR/workspace/data/memory/daily-summaries"

# ── Step 5: Copy image-gen skill ─────────────────────────────────────────────
echo "[5/9] Copying image-gen skill..."
mkdir -p "$GATEWAY_DIR/workspace/skills/image-gen"
if [[ -f "$IMAGE_GEN_SRC" ]]; then
  cp "$IMAGE_GEN_SRC" "$GATEWAY_DIR/workspace/skills/image-gen/generate.sh"
  chmod 644 "$GATEWAY_DIR/workspace/skills/image-gen/generate.sh"
else
  echo "  WARNING: image-gen script not found at $IMAGE_GEN_SRC"
fi

# ── Step 6: Write openclaw.json ───────────────────────────────────────────────
echo "[6/9] Writing openclaw.json..."

GATEWAY_TOKEN=$(openssl rand -hex 24)

cat > "$GATEWAY_DIR/openclaw.json" << CONFIGEOF
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "$MODEL"
      },
      "models": {
        "$MODEL": { "params": { "thinking": "off" } },
        "anthropic/claude-sonnet-4-6": {}
      },
      "workspace": "$GATEWAY_DIR/workspace",
      "compaction": { "mode": "safeguard" },
      "heartbeat": { "every": "0" }
    },
    "list": []
  },
  "tools": {
    "allow": [
      "read", "write", "edit",
      "web_search", "image",
      "memory_search", "memory_get",
      "exec"
    ],
    "web": {
      "search": {
        "provider": "perplexity",
        "perplexity": {
          "apiKey": "$(pass show parlour/perplexity-api-key 2>/dev/null || echo 'SET_PERPLEXITY_KEY')"
        }
      }
    }
  },
  "bindings": [],
  "commands": {
    "native": "auto",
    "nativeSkills": "auto",
    "restart": true,
    "ownerDisplay": "raw"
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "open",
      "botToken": "$BOT_TOKEN",
      "allowFrom": ["*"],
      "groupPolicy": "allowlist",
      "streaming": "partial"
    }
  },
  "gateway": {
    "port": $PORT,
    "mode": "local",
    "auth": {
      "mode": "token",
      "token": "$GATEWAY_TOKEN"
    }
  },
  "media": {}
}
CONFIGEOF

echo "  Gateway token: $GATEWAY_TOKEN"

# ── Step 7: Copy auth credentials ────────────────────────────────────────────
echo "[7/9] Copying auth credentials..."
if [[ -f "$LUNA_AUTH" ]]; then
  cp "$LUNA_AUTH" "$GATEWAY_DIR/agents/main/agent/auth-profiles.json"
  echo "  Copied auth-profiles.json"
else
  echo "  WARNING: Luna auth not found at $LUNA_AUTH"
fi

# ── Step 8: Create systemd service ───────────────────────────────────────────
echo "[8/9] Creating systemd service: $SERVICE_NAME..."

mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/${SERVICE_NAME}.service" << SERVICEEOF
[Unit]
Description=$NAME Companion Gateway
After=network.target

[Service]
Type=simple
Environment=OPENCLAW_CONFIG_PATH=$GATEWAY_DIR/openclaw.json
Environment=OPENCLAW_STATE_DIR=$GATEWAY_DIR
ExecStart=$OPENCLAW_BIN gateway --port $PORT
Restart=always
RestartSec=5
StandardOutput=append:/tmp/${ID}-gateway.log
StandardError=append:/tmp/${ID}-gateway.log

[Install]
WantedBy=default.target
SERVICEEOF

systemctl --user daemon-reload
systemctl --user enable "${SERVICE_NAME}"

# ── Step 9: Start gateway + register webhook ──────────────────────────────────
echo "[9/9] Starting gateway..."
systemctl --user start "${SERVICE_NAME}"
sleep 3

if systemctl --user is-active --quiet "${SERVICE_NAME}"; then
  echo "  ✓ Gateway running on port $PORT"
else
  echo "  ✗ Gateway failed to start — check: journalctl --user -u ${SERVICE_NAME} -n 20"
  exit 1
fi

# Register Telegram webhook via Cloudflare tunnel
WEBHOOK_URL="https://parlour.your-domain.com/api/telegram-webhook/$BOT_TOKEN"
REGISTER_RESULT=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/setWebhook?url=${WEBHOOK_URL}")
echo "  Webhook: $REGISTER_RESULT"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "✓ Character '$NAME' is ready!"
echo ""
echo "  Gateway dir:   $GATEWAY_DIR"
echo "  Port:          $PORT"
echo "  Gateway token: $GATEWAY_TOKEN"
echo "  Service:       systemctl --user status ${SERVICE_NAME}"
echo "  Logs:          tail -f /tmp/${ID}-gateway.log"
echo ""
echo "Next steps:"
echo "  1. Add a user binding: scripts/add-user.sh --character $ID --telegram-id <id>"
echo "  2. Add character card to the website frontend"
echo "  3. Store bot token: pass insert parlour/${ID}-bot-token"
echo ""
