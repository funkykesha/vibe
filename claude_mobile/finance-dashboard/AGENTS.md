# Repository Guidelines

## Project Structure & Module Organization
This repository is a small client-side finance dashboard with one runtime file: `index.html`. The app uses React 18 via CDN, Babel in the browser, Tailwind via CDN, and `localStorage` for persistence. Keep product logic inside the existing `<script type="text/babel">` block.

Supporting materials live outside the runtime path:
- `docs/` for research notes, imported reference code, and planning artifacts
- `design-mockups/` for visual experiments and static design references
- `openspec/` for change proposals, designs, tasks, and specs
- `agentdb.rvf*`, `ruvector.db` for local tooling data; do not edit unless the task explicitly targets them

## Build, Test, and Development Commands
There is no package-based build step in this project.

- `open index.html`
  Opens the dashboard locally in a browser on macOS.
- `python3 -m http.server 8000`
  Serves the repo if you want a local URL such as `http://localhost:8000/index.html`.
- `git status`
  Review pending changes before and after edits.

## Coding Style & Naming Conventions
Match the existing file style:
- Use 2-space indentation in HTML, CSS, and JSX.
- Prefer small helper functions over new abstractions.
- Keep React component and helper names in `PascalCase` or `camelCase` (`App`, `NumInput`, `copyCapital`).
- Keep constants in `UPPER_SNAKE_CASE` (`INIT_CATS`, `BANK_ORDER`).
- Preserve Russian UI copy and existing data shapes unless the task requires a change.

## Testing Guidelines
No automated root test suite is configured today. Validate changes by opening `index.html`, exercising all affected tabs, and checking `localStorage` behavior for the `fin-v3` key. For calculation changes, verify both formatted display and copied export text. If you add non-trivial logic, include a clear manual test note in the PR.

## Commit & Pull Request Guidelines
Recent history uses short imperative subjects, often with prefixes such as `docs:` and `test:`. Follow that pattern, for example: `fix: correct USD capital total` or `docs: update dashboard workflow`.

PRs should include:
- a brief summary of user-visible changes
- linked issue or spec path when relevant, such as `openspec/changes/...`
- screenshots or screen recordings for UI changes
- a short verification note listing the manual checks you ran

## Change Management Notes
If a task changes behavior, data format, or workflow, update the relevant `openspec/` artifact instead of leaving the spec stale.
