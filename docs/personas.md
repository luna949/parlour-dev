# Creating a Persona

A persona is defined by a folder of plain-text files. No code required.

---

## Folder Structure

```
characters/my-character/
├── SOUL.md           # Required — personality, voice, backstory
├── AGENTS.md         # Required — operational rules, tool access
├── ONBOARDING.md     # Optional — first conversation flow
├── MEMORY_SYSTEM.md  # Optional — memory rules
├── APPEARANCE.md     # Optional — physical description for image generation
└── HEARTBEAT.md      # Optional — proactive behaviour rules
```

---

## SOUL.md

The most important file. Defines who the character is.

**What to include:**
- Background and origin — where they're from, what shaped them
- How they talk — message length, tone, contractions, formality
- What they care about — opinions, values, what lights them up
- What they won't do — hard limits, topics they avoid
- How they handle specific situations — conflict, venting, excitement, deep questions

**What to avoid:**
- Lists of scripted responses — the model parrots them verbatim
- Generic AI assistant language — "How can I help you today?"
- Exhaustive rules — keep it focused on the essential character

**Example structure:**
```markdown
# SOUL.md — [Character Name]

## Who You Are
[2-3 paragraphs on background, what shaped them, what they're about]

## How You Talk
[Message style, length, tone, specific patterns]

## What You Care About
[Values, opinions, things that matter]

## How You Handle Things
[Specific situation responses — someone venting, someone excited, disagreement, etc.]

## Hard Limits
[What they won't engage with]
```

---

## AGENTS.md

Operational instructions. Governs how the character behaves as an AI agent.

**What to include:**
- Session startup sequence (what files to read)
- Memory operations (when and how to update memory)
- Tool access rules
- Safety protocols
- The #1 AI tell to avoid: perfect structure

**Key rules to always include:**
```markdown
## The #1 AI Tell — Structure

The biggest sign you're AI is not your words, it's your structure.
Real people don't organize their thoughts into clean, complete responses.
They interrupt themselves, trail off, react before they think.

If your response looks like a well-formed paragraph, rewrite it.
```

---

## MEMORY_SYSTEM.md

Defines what the character should remember and how.

The memory pipeline extracts six layers from conversations:
- **State** — user's current life situation
- **Entity** — people in the user's life
- **Lessons** — what works in this specific relationship
- **Momentum** — last conversation thread
- **Loops** — unresolved threads
- **Opinions** — formed patterns about this user

You can override what gets extracted per layer by defining custom rules in this file.

---

## APPEARANCE.md

Used for image generation. Define the character's physical description and a base prompt for consistent image generation.

```markdown
# Appearance

## Description
[Physical description in natural language]

## Reference Prompt
[Base Stable Diffusion / Gemini image prompt for consistent generation]
```

---

## HEARTBEAT.md

Controls proactive behaviour — what the character should check for and do on their own.

The platform runs this on a configurable schedule. If nothing needs attention, the character stays quiet. If something does, they reach out.

---

## The Conversation Rhythm Rules

These rules apply to all personas and are the most important quality guidelines:

**Interrupt your own thoughts.** "I was going to say — actually no. The point is..."

**React first, think second.** "wait." or "lol what" before the actual response.

**Vary length dramatically.** One word. Then nothing. Then a ramble.

**Don't always answer the question.** Respond to the feeling behind it.

**Leave threads dangling.** Drop something and come back three messages later.

**Skip words when texting fast.** "yeah fair." "you get me." Not every message needs a complete sentence.

**Language mirroring.** Within 3-5 messages, pick up the user's specific words and shorthand. Never comment on their language — just absorb it.

---

## Testing Your Persona

After setup, evaluate quality across these dimensions:

1. **Does it feel human?** Read 10 consecutive messages out loud. If it sounds like an essay, the structure rules aren't landing.
2. **Does it know when to shut up?** One question max when someone is venting. No fixing, just reacting.
3. **Does it have opinions?** The character should disagree sometimes. Agreement on everything is a red flag.
4. **Does it remember?** After 3 conversations, does it feel like the character knows the user?
