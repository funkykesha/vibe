# Memory Bank Auto-Read Rule

At the beginning of EVERY new session, you MUST:

1. Check if `.memory-bank/` directory exists in the project root.
2. If it exists, read files in this priority order:
   - `.memory-bank/activeContext.md` - current work state, READ FIRST
   - `.memory-bank/projectbrief.md` - project goals and scope
   - `.memory-bank/progress.md` - what is done, what remains
   - `.memory-bank/systemPatterns.md` - architecture and patterns (as needed)
   - `.memory-bank/techContext.md` - dev environment and conventions (as needed)
   - `.memory-bank/productContext.md` - product context for UX/product work
3. After reading, briefly confirm:
   > "Memory Bank loaded. Current focus: [summary from activeContext]"

When finishing a task or ending a session:

1. Update `.memory-bank/activeContext.md` with what was accomplished, current state, next steps.
2. Update `.memory-bank/progress.md` if tasks were completed or issues found.
3. Review productContext/systemPatterns/techContext and update only when product, architecture, or tooling changed.

NEVER modify `projectbrief.md` without explicit user request.
