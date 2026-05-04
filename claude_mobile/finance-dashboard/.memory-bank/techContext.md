# Tech Context

## Development Environment Setup
- Open `index.html` directly in a browser only for static inspection; for the working app use the FastAPI-served URL.
- Run the backend locally with `python3.13 -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000`.
- Custom Codex finance agents live in `~/.codex/agents/`; global agent limits live in `~/.codex/config.toml`.

## Build and Deploy
- No frontend build step.
- Backend dependencies are listed in `backend/requirements.txt`.
- Data persistence uses `fin-v3` in localStorage plus backend API storage.
- Deployment remains later-stage work owned by `deployment-readiness`, not an immediate implementation concern.

## Code Style and Conventions
- **Language**: HTML, JSX, Python.
- **Formatter**: None enforced in-repo.
- **Linter**: None enforced in-repo.
- **Naming**: PascalCase for components, camelCase for helpers/state, UPPER_SNAKE_CASE for constants.
- **Commit format**: Short imperative subjects, often prefixed like `fix:` or `docs:`.
- **Execution discipline**: Use OpenSpec stage verification and role-specific subagents for remaining implementation work.

## External Dependencies

| Service | Purpose | Docs | Constraints |
|---------|---------|------|-------------|
| React CDN | UI runtime | unpkg CDN | No npm install |
| Babel CDN | JSX transpilation | unpkg CDN | Browser-only transpile |
| Tailwind CDN | Styling | CDN | Utility classes only |
| FastAPI backend | Persistence/API | repo code | Must keep schema in sync |
| Codex custom agents | Stage-specific implementation roles | local config | May require app restart after config changes |
| Context7 MCP | Dependency research evidence | MCP | Use for external behavior questions in later specs |

---
*Updated when dev environment or conventions change.*
