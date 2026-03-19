# Roadmap

## Where We Are

Parlour is in **friends beta** — two characters live (Roberto and Marcus), deployed on Telegram, invite-only. The core product is working: persistent memory, human-quality conversation, sandboxed containers, proactive initiation.

The infrastructure is a prototype. The platform vision is clear.

---

## Phase 1 — Current (Friends Beta)

- [x] Two characters live (Roberto, Marcus)
- [x] Per-user sandboxed Docker containers
- [x] Post-session memory extraction pipeline
- [x] Spontaneous initiation (stochastic cron)
- [x] Invite-only registration website
- [x] Secrets management (GPG/pass)
- [x] Deployment scripts (`add-character.sh`, `add-user.sh`, `bootstrap.sh`)

---

## Phase 2 — Platform Foundation

**Goal:** move from scattered scripts to a coherent service.

- [ ] Platform service layer — channel adapters, core routing, user registry
- [ ] Database-backed identity — move from flat files to SQLite user registry
- [ ] Web channel adapter — embed characters on any website
- [ ] Character registry — adding a character is a config change, not an infrastructure project
- [ ] Cognitive memory service — memory as an API, not files written by the agent
- [ ] Evaluation layer — conversation quality scoring, LLM-as-judge

---

## Phase 3 — Relationship Depth

**Goal:** make the relationship feel real over time.

- [ ] Relationship depth progression — Stranger → Acquaintance → Friend → Close Friend → Inner Circle
- [ ] Life rhythm — characters have sleep schedules and moods by time of day
- [ ] Deep sleep memory — weekly pattern recognition across sessions, promotes recurring themes
- [ ] Cross-session momentum — characters pick up threads from days ago naturally
- [ ] User-facing memory transparency — users can see and edit what a character knows about them

---

## Phase 4 — Multi-Channel

**Goal:** characters exist wherever users are.

- [ ] WhatsApp adapter (via Meta Business API)
- [ ] Cross-channel identity — same user, same character, same memory across channels
- [ ] Web chat widget — embeddable on any site
- [ ] Voice channel — basic voice note support

---

## Phase 5 — Scale

**Goal:** 100 characters, thousands of users.

- [ ] Webhook router — single endpoint for all characters
- [ ] Agent pool manager — sleep/wake lifecycle, concurrency limits
- [ ] Container lifecycle — archive inactive users, restore on demand
- [ ] Analytics — which characters retain users, conversation quality metrics

---

## Phase 6 — White-Label Platform

**Goal:** deploy Parlour for enterprise customers.

- [ ] Tenant isolation — per-tenant data partitioning and encryption
- [ ] Custom domain support
- [ ] SSO/SAML for enterprise identity
- [ ] Audit logging — every message, every tool call, every memory write
- [ ] GDPR compliance — user data export and deletion
- [ ] Admin portal — usage, user management, character management
- [ ] Declarative network policy — per-character egress allowlists

---

## Use Cases We're Building Toward

**Consumer companions** — quality platonic adult friendships with intellectual depth. The white space nobody credible owns.

**Professional advisors** — same architecture, different personas. A financial advisor who knows your situation over months. A career coach who remembers every interview and setback.

**Enterprise white-label** — companies deploy branded personas for their customers. A bank's financial wellness companion. A healthcare company's mental wellness character.

---

## What Makes This Different

Most AI companions remember facts. Parlour personas develop **understanding**.

The memory system doesn't just store what was said — it extracts opinions about how this person communicates, what they avoid, what lights them up. It surfaces unresolved threads. It builds a model of the relationship over time that compounds with every conversation.

The container architecture means this scales: each user's relationship is isolated, private, and portable. The persona is config. The platform is the moat.
