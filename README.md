# Parlour

**AI companions with persistent memory, real personality, and multi-channel delivery.**

Parlour is a platform for deploying AI persona agents that build genuine relationships with users over time. Unlike generic chatbots, Parlour personas remember context across sessions, develop opinions, adapt their communication style to each user, and reach out proactively when something relevant comes to mind.

---

## What This Is

Parlour has two layers:

**1. The persona runtime** — each character (Roberto, Marcus, or any persona you define) runs as a sandboxed agent with:
- Persistent memory across sessions (facts, preferences, people, events)
- Configurable personality via plain-text files
- Tool access (web search, image generation, memory read/write)
- Proactive initiation (characters can reach out on their own schedule)

**2. The platform layer** *(in progress)* — a channel-agnostic service that routes messages from any surface (Telegram, WhatsApp, web chat, voice) to the right agent, manages user identity across channels, and owns the memory pipeline independently of the agent runtime.

---

## Current State

- **Two characters live:** Roberto (Italian philosopher friend) and Marcus (direct, warm outsider-perspective friend)
- **Deployed on Telegram** with per-user sandboxed containers
- **Memory system:** post-session extraction pipeline using Gemini embeddings + SQLite-vec
- **Spontaneous initiation:** stochastic cron-based proactive messaging
- **Secrets management:** GPG-encrypted via `pass`
- **Infrastructure:** Docker sandboxes, systemd services, Cloudflare Tunnel

---

## Architecture

```
Users (any channel)
      │
      ▼
Channel Adapters          ← Telegram, WhatsApp, web, voice (planned)
      │
      ▼
Core Service              ← identity routing, session management, user registry
      │
      ▼
OpenClaw (headless)       ← agent runtime, LLM orchestration, tool execution
      │
      ▼
Persona Container         ← sandboxed, read-only personality, writable memory
```

Each persona runs in an isolated Docker container:
- Personality files (`SOUL.md`, `AGENTS.md`) are immutable at runtime (`444`)
- User memory lives in a per-user `data/` directory
- No cross-user data access is possible

See [`docs/architecture.md`](docs/architecture.md) for the full design.

---

## Repository Structure

```
parlour/
├── characters/           # Persona definitions
│   └── example/          # Template for a new character
├── channels/             # Channel adapter interfaces (planned)
├── core/                 # Routing, identity, session management (planned)
├── docker/               # Container image definitions
│   └── Dockerfile        # parlour-companion image
├── scripts/              # Deployment utilities
│   ├── add-character.sh  # Add a new character
│   └── add-user.sh       # Provision a user for a character
├── docs/                 # Documentation
│   ├── architecture.md   # System design
│   ├── roadmap.md        # Feature roadmap
│   ├── setup.md          # Full setup guide
│   └── personas.md       # How to create a persona
├── docker-compose.yml    # Full stack local deployment
└── config.example.yaml   # Configuration template
```

---

## Quick Start

### Prerequisites

- Ubuntu 22.04+ or macOS
- Docker + Docker Compose
- Node.js 22+
- OpenClaw CLI (`npm install -g openclaw`)
- A Telegram bot token (from [@BotFather](https://t.me/botfather))

### Setup

```bash
# 1. Clone
git clone https://github.com/<org>/parlour.git
cd parlour

# 2. Configure
cp config.example.yaml config.yaml
# Edit config.yaml — add your bot token, API keys

# 3. Build the companion image
docker build -t parlour-companion:latest -f docker/Dockerfile .

# 4. Add your first character
bash scripts/add-character.sh \
  --name "Roberto" \
  --id "roberto" \
  --bot-token "YOUR_BOT_TOKEN" \
  --port 18790 \
  --personality ./characters/example/

# 5. Add a user
bash scripts/add-user.sh \
  --character "roberto" \
  --telegram-id "YOUR_TELEGRAM_ID" \
  --username "you"
```

Message your bot on Telegram. Roberto will respond.

Full setup guide: [`docs/setup.md`](docs/setup.md)

---

## Configuration

All secrets should be stored in environment variables or a secrets manager (`pass` recommended). Never commit secrets to the repository.

See [`config.example.yaml`](config.example.yaml) for the full configuration reference.

---

## Adding a Character

A character is a folder containing personality files:

```
characters/my-character/
├── SOUL.md           # Who they are — voice, personality, backstory
├── AGENTS.md         # Operational instructions, tool access rules
├── ONBOARDING.md     # First conversation flow
├── MEMORY_SYSTEM.md  # What to remember and how
├── APPEARANCE.md     # Physical description (for image generation)
└── HEARTBEAT.md      # Proactive behaviour rules
```

See [`docs/personas.md`](docs/personas.md) for the full guide.

---

## Roadmap

See [`docs/roadmap.md`](docs/roadmap.md) for the full roadmap. Key upcoming areas:

- **Platform service layer** — channel-agnostic routing, cross-channel identity
- **Cognitive memory service** — structured memory API replacing file-based storage
- **Web channel adapter** — embed any character on a website
- **WhatsApp support** — via Meta Business API
- **Relationship depth system** — visible progression from stranger to close friend
- **Evaluation layer** — conversation quality scoring, LLM-as-judge

---

## Contributing

This project is in active development. If you're interested in contributing:

1. Read [`docs/architecture.md`](docs/architecture.md) first
2. Check open issues for current priorities
3. For significant changes, open a discussion before submitting a PR

---

## License

Apache 2.0 — see [LICENSE](LICENSE).
