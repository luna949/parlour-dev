# Architecture

## Overview

Parlour is built around a clean separation of concerns:

- **Personas** are configuration, not infrastructure
- **The runtime** (OpenClaw) handles LLM calls, tools, and sandboxing
- **The platform** owns channels, identity, and memory
- **The containers** are stateless — all durable state lives outside them

---

## Current Architecture

```
Telegram API
     │
     ▼ (webhook)
OpenClaw Gateway          ← one per character, port per character
     │
     ▼
Agent Container           ← Docker sandbox, per user
     │
     ├── /workspace (read-only) ← personality files (SOUL.md, AGENTS.md, etc.)
     └── /workspace/data (rw)   ← user memory (facts, events, preferences)
```

### Sandboxing

Each user conversation runs in an isolated Docker container:

- `parlour-companion:latest` base image (Node 22 + Python 3 + curl)
- Personality files locked at `444` — immutable during runtime
- `data/` directory writable — memory persists to host via volume mount
- No Docker socket in agent containers — prevents container escape

### Memory Pipeline

After each conversation, a post-session pipeline extracts durable facts:

```
Session ends (30min idle)
      ↓
Watcher (cron, 10min) — detects idle sessions
      ↓
REM extraction (Gemini Flash) — structured fact extraction per layer
      ↓
Consolidation — conflict detection via vector similarity, ADD/UPDATE/IGNORE
      ↓
MEMORY_CONTEXT.md — injected into agent context on next session start
```

Memory is organised into six layers:
- **State** — current life situation
- **Entity** — people in the user's life
- **Lessons** — what works and what doesn't
- **Momentum** — last conversation thread
- **Loops** — unresolved threads
- **Opinions** — formed patterns about this user

### Secrets

All secrets stored in GPG-encrypted `pass` store. No secrets in code or config files committed to the repository.

---

## Target Architecture (Platform Service)

The current model (one gateway per character) works up to ~8 characters. Beyond that, a platform service layer is needed.

```
Users (any channel)
      │
 ┌────┴────┐
 │ Channel │  Telegram, WhatsApp, web, voice, SMS
 │ Adapters│  Each adapter normalises messages to a common shape
 └────┬────┘
      │ { user_id, character_id, text, media }
      ▼
 ┌─────────┐
 │  Core   │  Identity resolution, session routing, user registry
 │ Service │  SQLite-backed, cross-channel identity linking
 └────┬────┘
      │
      ▼
 ┌─────────┐
 │ OpenClaw│  Headless — no channels, no bot tokens
 │ Runtime │  Agent execution, tool calls, LLM orchestration
 └────┬────┘
      │
      ▼
 ┌─────────┐
 │ Persona │  Sandboxed container, stateless
 │Container│  Personality (read-only) + memory API calls
 └─────────┘
      │
      ▼
 ┌─────────┐
 │Cognitive│  Memory extraction, storage, retrieval
 │ Service │  Postgres + pgvector, REST API
 └─────────┘
```

### Key design principles

**Channel-agnostic.** The same persona works across Telegram, WhatsApp, web chat, and voice without code changes. Channel adapters normalise all messages to the same shape before they reach the runtime.

**Identity as a platform primitive.** A user is identified by a platform UUID, not a channel-specific ID. One person can talk to the same character across multiple channels with continuous memory.

**Stateless containers.** Persona containers hold no durable state. All memory is owned by the cognitive service. Containers can be started, stopped, and replaced without data loss.

**Personas as config.** Adding a new character is adding a folder. No gateway configuration, no systemd services, no port allocation. The platform picks it up and handles the rest.

---

## Scaling

| Scale | Architecture | Notes |
|-------|-------------|-------|
| 1-8 characters | One gateway per character (current) | Manageable manually |
| 8-50 characters | Platform service + webhook router | One entry point, character registry |
| 50-100+ characters | Agent pool manager | Sleep/wake lifecycle, concurrency limits |
| 100+ / cloud | Kubernetes + PVC | Containers as pods, persistent volumes |

Cold start time (~2-4 seconds) is acceptable for this use case — it reads as natural human response time.

---

## Security Model

| Layer | Mechanism | Status |
|-------|-----------|--------|
| Filesystem isolation | Docker volume mounts + read-only FS | Planned |
| Network isolation | Docker internal network + egress allowlist | Planned |
| Syscall restriction | Docker seccomp profile | Planned |
| Personality immutability | `chmod 444` on personality files | Live |
| Secret storage | GPG-encrypted `pass` | Live |
| Cross-user isolation | Separate containers per user | Live |
| Inference routing | Via OpenClaw gateway (no direct LLM calls from container) | Live |
