# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Folder for **ideation, brainstorming, and research** on multiple product concepts. These are **not yet production projects** — they are:

- Concept validation
- Feature planning
- Architecture exploration
- Feedback/critique cycles

Each idea document evolves through feedback and refinement.

## Projects Under Exploration

### 1. **CodeSpark** — Project idea generator for developers

**Purpose:** Combat blank-page syndrome by generating project ideas through binary choice flow

**Concept:** Interactive "idea engine" that guides users through 4 rounds of binary choices to narrow down a project specification and tech stack

**Current State:** Concept + design + critical feedback doc  
**Key Files:** `Генерация идей.md`

**Core Loop:**
1. User chooses between two options (Frontend vs Backend, etc.)
2. LLM generates next pair of choices (context-aware, narrowing scope)
3. Every 4 choices: synthesis checkpoint showing emerging project
4. Final: project name, tech stack, 3-5 key features

**Tech Stack (Planned):**
- Frontend: React/Next.js, single page
- Backend: Node.js, LLM integration (Groq/Gemini Flash)
- Latency target: <500ms per choice generation

**Stage:** Validation phase
- ✅ Core gameplay loop designed
- ✅ UX/UI critique collected
- ⚠️ Audience clarity needed (juniors? experienced devs?)
- ⚠️ LLM quality filtering (using knowledge graph vs free-form)

**Next Steps:**
- Validate market (Reddit/Discord survey)
- Build MVP with fixed knowledge graph (rounds 1-3)
- Add LLM synthesis for final output only
- Implement pre-generation (rounds 5-7 in background)

**Priority Extensions:**
1. Export result (README + file structure + scaffold)
2. Save & share ideas (social sharing, seed URLs)
3. Metrics & learning (track popular paths, user behavior)

---

### 2. **Child behavior redirect app** — Parent decision support

**Purpose:** Help parents redirect children's disruptive behavior with quick, actionable suggestions (in-the-moment parenting tool)

**Concept:** "When child is doing X → open app → get idea in 1 tap"

**Current State:** MVP specification only  
**Key Files:** `child.md` (renamed from root level)

**Features (MVP):**
- Single-screen UI with buttons:
  - 🎤 Voice input ("child is throwing things")
  - ⚡ Quick mode (no input, just generate)
- Settings: child age (slider), chaos level (calm/active/wild)
- Content delivery: suggestion card with:
  - 🧠 What to say
  - 🎯 What to do
  - ⏱ Duration (~1-5 min)
  - Feedback buttons: 👍 / 👎 / 🔁

**Tech Stack (MVP):**
- Frontend: React/Next.js PWA, Web Speech API
- Backend: Zero (initially — just JSON with scenarios)
- Content: Pre-made database of 30-50 scenarios (more important than code)
- Audio: Text-to-speech for immediate action (not reading)

**Content Categories:**
- Destructive behavior (throwing, scattering)
- Clingy/whiny
- Hyperactive
- Bored
- Before sleep
- Not listening

**Stage:** Specification phase
- ✅ MVP flow defined
- ✅ Content structure clear (scenario format)
- ❌ No code yet
- ❌ No user validation

**Version 1 (1-2 days):**
- Save ratings (which ideas work)
- Personalization (show 👍 more, hide 👎)
- Context (time of day, location)

**Version 2 (with LLM):**
- Generate instead of database lookups
- Custom scenarios based on voice input
- Learning from feedback

---

## Working with This Folder

1. **Read the .md files** for full concept/feedback
2. **Edit inline** to iterate on ideas
3. **Extract to real project folder** once concept is solid & committed
4. **Keep comments/feedback** — part of validation process
5. **No build commands** — research only (until code phase starts)

## Guidance Rules

- Keep ideation notes raw (no need for polish)
- Include both concept AND critical feedback (learn from pushback)
- Document unknowns explicitly ("Who is the audience?", "Need validation")
- When ready to build: create new folder with `npm init`, proper project structure
- Link back from new project to original ideation docs

---

## Common Patterns Across Ideas

| Pattern | Purpose |
|---------|---------|
| **MVP scope** | Build in 1 day without infrastructure |
| **Content > Code** | Pre-made content beats smart generation (early) |
| **Validation first** | Test hypotheses before architecture |
| **Async enhancement** | v1 is simple; v2 adds intelligence |
| **User feedback loop** | Ratings/shares drive v1→v2 iteration |
