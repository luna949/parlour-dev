#!/usr/bin/env bash
# ============================================================
# bootstrap.sh — Set up The Parlour on a fresh machine
#
# What you need before running this:
#   1. Ubuntu 22.04+ or Debian 12+
#   2. sudo access
#   3. Your GPG key exported: gpg --export-secret-keys > key.gpg
#   4. Your pass store: tar -czf pass-store.tar.gz ~/.password-store/
#
# Usage:
#   bash bootstrap.sh
# ============================================================
set -euo pipefail

echo ""
echo "╔══════════════════════════════════════╗"
echo "║     The Parlour — Bootstrap          ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── 1. System dependencies ────────────────────────────────────────────────────
echo "[1/8] Installing system dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
  git curl wget gnupg pass \
  nodejs npm \
  ca-certificates lsb-release

# ── 2. Docker ─────────────────────────────────────────────────────────────────
echo "[2/8] Installing Docker..."
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
  sudo chmod 666 /var/run/docker.sock
  echo "  Docker installed. NOTE: You may need to log out and back in."
else
  echo "  Docker already installed"
fi

# ── 3. OpenClaw ───────────────────────────────────────────────────────────────
echo "[3/8] Installing OpenClaw..."
if ! command -v openclaw &>/dev/null; then
  npm install -g openclaw
else
  echo "  OpenClaw already installed"
fi

# ── 4. Clone repo ─────────────────────────────────────────────────────────────
echo "[4/8] Cloning The Parlour repo..."
REPO_DIR="$HOME/parlour"
if [[ ! -d "$REPO_DIR" ]]; then
  git clone https://github.com/<your-github-org>/parlour.git "$REPO_DIR"
else
  echo "  Repo already cloned at $REPO_DIR"
  cd "$REPO_DIR" && git pull
fi

# ── 5. Import GPG key + pass store ───────────────────────────────────────────
echo "[5/8] Setting up secrets..."
echo ""
echo "  You need to restore your GPG key and pass store."
echo "  If you have them backed up, run:"
echo ""
echo "    gpg --import key.gpg"
echo "    tar -xzf pass-store.tar.gz -C ~/"
echo ""
echo "  Then verify with: pass show parlour/roberto-bot-token"
echo ""
read -p "  Press Enter when secrets are ready (or Ctrl+C to pause)..."

# Verify pass works
pass show parlour/roberto-bot-token > /dev/null 2>&1 && echo "  ✓ Secrets verified" || {
  echo "  ✗ Secrets not found — please set up pass before continuing"
  exit 1
}

# ── 6. Pull Docker image ──────────────────────────────────────────────────────
echo "[6/8] Building parlour-companion Docker image..."
cd "$REPO_DIR/projects/companion"
docker build -t parlour-companion:latest -f docker/Dockerfile.companion docker/
echo "  ✓ Image built"

# ── 7. Add characters ─────────────────────────────────────────────────────────
echo "[7/8] Setting up characters..."

cd "$REPO_DIR/projects/companion"

# Roberto
echo "  Adding Roberto..."
bash scripts/add-character.sh \
  --name "Roberto" \
  --id "roberto" \
  --bot-token "$(pass show parlour/roberto-bot-token)" \
  --port 18790 \
  --personality ./characters/roberto/

# Marcus
echo "  Adding Marcus..."
bash scripts/add-character.sh \
  --name "Marcus" \
  --id "marcus" \
  --bot-token "$(pass show parlour/marcus-bot-token)" \
  --port 18795 \
  --personality ./characters/marcus/

# ── 8. Start registration server ─────────────────────────────────────────────
echo "[8/8] Starting registration server..."
source ./load-secrets.sh

cat > "$HOME/.config/systemd/user/companion-registration.service" << SERVICEEOF
[Unit]
Description=Parlour Registration Server
After=network.target

[Service]
Type=simple
Environment=PORT=3456
Environment=COMPANION_ADMIN_SECRET=${ADMIN_SECRET}
Environment=ROBERTO_BOT_TOKEN=${ROBERTO_BOT_TOKEN}
Environment=MARCUS_BOT_TOKEN=${MARCUS_BOT_TOKEN}
WorkingDirectory=$REPO_DIR/projects/companion/src/backend
ExecStart=$(which node) server.js
Restart=always
RestartSec=5
StandardOutput=append:/tmp/companion-server.log
StandardError=append:/tmp/companion-server.log

[Install]
WantedBy=default.target
SERVICEEOF

systemctl --user daemon-reload
systemctl --user enable companion-registration
systemctl --user start companion-registration

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════╗"
echo "║     The Parlour is running! 🎭       ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Services:"
echo "  Registration server: http://localhost:3456"
echo "  Roberto gateway:     http://localhost:18790"
echo "  Marcus gateway:      http://localhost:18795"
echo ""
echo "Logs:"
echo "  tail -f /tmp/roberto-gateway.log"
echo "  tail -f /tmp/marcus-gateway.log"
echo "  tail -f /tmp/companion-server.log"
echo ""
echo "Next: set up Cloudflare Tunnel pointing to :3456 for the website"
echo ""
