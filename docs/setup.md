# Setup Guide

This guide covers a complete local setup from scratch.

---

## Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| Ubuntu / macOS | 22.04+ / Ventura+ | Windows WSL2 also supported |
| Docker | 24+ | With Docker Compose v2 |
| Node.js | 22+ | |
| OpenClaw CLI | latest | `npm install -g openclaw` |
| Telegram Bot Token | — | Create via [@BotFather](https://t.me/botfather) |
| Gemini API Key | — | [Google AI Studio](https://aistudio.google.com) |
| Perplexity API Key | — | [Perplexity API](https://www.perplexity.ai/api) |

---

## Step 1: Clone and Configure

```bash
git clone https://github.com/<org>/parlour.git
cd parlour
cp config.example.yaml config.yaml
```

Edit `config.yaml` with your API keys and bot tokens. See [Configuration](#configuration) below.

---

## Step 2: Set Up Secrets

Parlour uses [`pass`](https://www.passwordstore.org/) for secret storage. If you don't have it:

```bash
# Install
sudo apt install pass gnupg -y   # Ubuntu
brew install pass gnupg           # macOS

# Generate a GPG key
gpg --full-generate-key
# Choose RSA 4096, no expiry, set a passphrase

# Get your key ID
gpg --list-keys
# Copy the fingerprint (40-char hex string)

# Initialise pass
pass init <YOUR_KEY_ID>
```

Add your secrets:

```bash
pass insert parlour/roberto-bot-token
pass insert parlour/gemini-api-key
pass insert parlour/perplexity-api-key
```

Load secrets into environment:

```bash
source ./load-secrets.sh
```

---

## Step 3: Build the Docker Image

```bash
docker build -t parlour-companion:latest -f docker/Dockerfile .
```

Verify:

```bash
docker run --rm parlour-companion:latest node --version
docker run --rm parlour-companion:latest python3 --version
```

---

## Step 4: Add a Character

```bash
bash scripts/add-character.sh \
  --name "Roberto" \
  --id "roberto" \
  --bot-token "$(pass show parlour/roberto-bot-token)" \
  --port 18790 \
  --personality ./characters/example/
```

This will:
1. Create `~/.openclaw-roberto/` with gateway config
2. Copy and lock personality files
3. Create a systemd user service
4. Start the gateway
5. Register the Telegram webhook

Verify the gateway is running:

```bash
systemctl --user status roberto-gateway
tail -f /tmp/roberto-gateway.log
```

---

## Step 5: Add a User

Find your Telegram user ID:
1. Message [@userinfobot](https://t.me/userinfobot) on Telegram
2. It will reply with your numeric ID

```bash
bash scripts/add-user.sh \
  --character "roberto" \
  --telegram-id "YOUR_TELEGRAM_ID" \
  --username "your-name"
```

---

## Step 6: Test

Message your bot on Telegram. You should receive a response within a few seconds.

---

## Configuration

`config.yaml` controls all runtime behaviour:

```yaml
# Character defaults
defaults:
  model: google/gemini-3-pro-preview
  sandbox:
    image: parlour-companion:latest

# Memory pipeline
memory:
  idle_threshold_minutes: 30   # How long before a session is processed
  min_messages: 10             # Minimum messages to trigger extraction

# Spontaneous initiation
spontaneous:
  base_probability: 0.08       # 8% chance per 2-hour check
  min_cooldown_hours: 6        # Don't message if talked within 6 hours
  max_per_day: 1               # Max spontaneous messages per user per day
```

---

## Managing Characters

**List running gateways:**
```bash
systemctl --user list-units | grep gateway
```

**Restart a gateway:**
```bash
systemctl --user restart roberto-gateway
```

**View logs:**
```bash
tail -f /tmp/roberto-gateway.log
```

**Stop a gateway:**
```bash
systemctl --user stop roberto-gateway
```

---

## Updating Personality Files

Personality files are locked at runtime. To update:

```bash
# 1. Edit the master file in characters/
vim characters/roberto/SOUL.md

# 2. Sync to user workspaces (the add-character script handles this)
bash scripts/sync-personality.sh --character roberto

# 3. Restart the gateway
systemctl --user restart roberto-gateway
```

---

## Troubleshooting

**Bot doesn't respond**
- Check the gateway is running: `systemctl --user status roberto-gateway`
- Check the webhook is registered: `curl https://api.telegram.org/bot<TOKEN>/getWebhookInfo`
- Check logs: `tail -50 /tmp/roberto-gateway.log`

**Memory not updating**
- Check the memory timer: `systemctl --user status parlour-memory.timer`
- Run manually: `cd src/memory && node job.js --config ../../config.yaml`

**Docker container fails to start**
- Check image exists: `docker images | grep parlour-companion`
- Rebuild: `docker build -t parlour-companion:latest -f docker/Dockerfile .`
